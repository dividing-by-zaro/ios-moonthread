import datetime
import time

from sqlalchemy import and_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import DemoPeriod, Period
from app.schemas import PeriodStats

MAX_DATE_RANGE_YEARS = 10

# Owner-keyed stats cache: { owner: {"value": ..., "expires_at": ...} }
_stats_cache: dict[str, dict[str, object]] = {}
_STATS_TTL_SECONDS = 30


def _model(owner: str):
    return DemoPeriod if owner == "demo" else Period


def _validate_date_range(d: datetime.date) -> None:
    today = datetime.date.today()
    lower = today - datetime.timedelta(days=MAX_DATE_RANGE_YEARS * 365)
    upper = today + datetime.timedelta(days=1)  # allow today, reject future
    if d < lower or d > upper:
        raise ValueError(f"Date must be between {lower} and {upper}")


async def _check_overlap(
    db: AsyncSession,
    start_date: datetime.date,
    end_date: datetime.date | None,
    owner: str,
    exclude_id: int | None = None,
) -> None:
    """Raise ValueError if the given range overlaps any existing period."""
    M = _model(owner)
    effective_end = end_date if end_date is not None else datetime.date.max
    # A overlaps B when A.start <= B.end AND A.end >= B.start
    conditions = [
        M.start_date <= effective_end,
    ]
    # For periods with NULL end_date (open), they extend to infinity
    # so they always satisfy "existing.end >= start_date".
    # For periods with an end_date, check normally.
    conditions.append(
        (M.end_date >= start_date) | (M.end_date.is_(None))
    )
    if exclude_id is not None:
        conditions.append(M.id != exclude_id)
    result = await db.execute(select(M.id).where(and_(*conditions)).limit(1))
    if result.scalar_one_or_none() is not None:
        raise ValueError("Date range overlaps with an existing period")


def _invalidate_stats_cache(owner: str) -> None:
    _stats_cache.pop(owner, None)


async def list_periods(db: AsyncSession, owner: str) -> list:
    M = _model(owner)
    result = await db.execute(
        select(M).order_by(M.start_date.desc())
    )
    return list(result.scalars().all())


async def create_period(db: AsyncSession, start_date: datetime.date, owner: str):
    M = _model(owner)
    _validate_date_range(start_date)

    # Check no open period exists
    result = await db.execute(
        select(M).where(M.end_date.is_(None))
    )
    open_period = result.scalar_one_or_none()
    if open_period:
        raise ValueError("An open period already exists. End it before starting a new one.")

    await _check_overlap(db, start_date, None, owner)

    period = M(start_date=start_date)
    db.add(period)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise ValueError("A period with this start date already exists")
    await db.refresh(period)
    _invalidate_stats_cache(owner)
    return period


async def end_period(db: AsyncSession, period_id: int, end_date: datetime.date, owner: str):
    M = _model(owner)
    _validate_date_range(end_date)

    result = await db.execute(
        select(M).where(M.id == period_id)
    )
    period = result.scalar_one_or_none()
    if not period:
        raise LookupError("Period not found")
    if period.end_date is not None:
        raise ValueError("Period is already ended")
    if end_date < period.start_date:
        raise ValueError("end_date must be >= start_date")

    await _check_overlap(db, period.start_date, end_date, owner, exclude_id=period_id)

    period.end_date = end_date
    await db.commit()
    await db.refresh(period)
    _invalidate_stats_cache(owner)
    return period


async def update_period(
    db: AsyncSession,
    period_id: int,
    start_date: datetime.date,
    end_date: datetime.date | None,
    owner: str,
):
    M = _model(owner)
    _validate_date_range(start_date)
    if end_date is not None:
        _validate_date_range(end_date)

    result = await db.execute(
        select(M).where(M.id == period_id)
    )
    period = result.scalar_one_or_none()
    if not period:
        raise LookupError("Period not found")
    if end_date is not None and end_date < start_date:
        raise ValueError("end_date must be >= start_date")

    await _check_overlap(db, start_date, end_date, owner, exclude_id=period_id)

    period.start_date = start_date
    period.end_date = end_date
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise ValueError("A period with this start date already exists")
    await db.refresh(period)
    _invalidate_stats_cache(owner)
    return period


async def delete_period(db: AsyncSession, period_id: int, owner: str) -> None:
    M = _model(owner)
    result = await db.execute(
        select(M).where(M.id == period_id)
    )
    period = result.scalar_one_or_none()
    if not period:
        raise LookupError("Period not found")
    await db.delete(period)
    await db.commit()
    _invalidate_stats_cache(owner)


async def get_stats(db: AsyncSession, owner: str) -> PeriodStats:
    M = _model(owner)
    now = time.monotonic()
    cached = _stats_cache.get(owner)
    if cached is not None and cached["value"] is not None and now < cached["expires_at"]:
        return cached["value"]

    result = await db.execute(
        select(M).order_by(M.start_date.asc())
    )
    periods = list(result.scalars().all())

    # Current open period
    current = next((p for p in periods if p.end_date is None), None)

    # Average period length (completed only)
    completed = [p for p in periods if p.end_date is not None]
    avg_period_length = None
    if completed:
        lengths = [(p.end_date - p.start_date).days + 1 for p in completed]
        avg_period_length = round(sum(lengths) / len(lengths), 1)

    # Average cycle length (gap between consecutive period starts)
    avg_cycle_length = None
    if len(periods) >= 2:
        cycles = []
        for i in range(len(periods) - 1):
            gap = (periods[i + 1].start_date - periods[i].start_date).days
            cycles.append(gap)
        avg_cycle_length = round(sum(cycles) / len(cycles), 1)

    # Predicted next start
    predicted = None
    if avg_cycle_length and periods:
        last_start = periods[-1].start_date
        predicted = last_start + datetime.timedelta(days=round(avg_cycle_length))

    stats = PeriodStats(
        average_cycle_length=avg_cycle_length,
        average_period_length=avg_period_length,
        current_period=current,
        predicted_next_start=predicted,
    )

    _stats_cache[owner] = {"value": stats, "expires_at": now + _STATS_TTL_SECONDS}

    return stats
