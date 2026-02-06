import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Period
from app.schemas import PeriodStats


async def list_periods(db: AsyncSession) -> list[Period]:
    result = await db.execute(select(Period).order_by(Period.start_date.desc()))
    return list(result.scalars().all())


async def create_period(db: AsyncSession, start_date: datetime.date) -> Period:
    # Check no open period exists
    result = await db.execute(select(Period).where(Period.end_date.is_(None)))
    open_period = result.scalar_one_or_none()
    if open_period:
        raise ValueError("An open period already exists. End it before starting a new one.")

    period = Period(start_date=start_date)
    db.add(period)
    await db.commit()
    await db.refresh(period)
    return period


async def end_period(db: AsyncSession, period_id: int, end_date: datetime.date) -> Period:
    result = await db.execute(select(Period).where(Period.id == period_id))
    period = result.scalar_one_or_none()
    if not period:
        raise LookupError("Period not found")
    if period.end_date is not None:
        raise ValueError("Period is already ended")
    if end_date < period.start_date:
        raise ValueError("end_date must be >= start_date")

    period.end_date = end_date
    await db.commit()
    await db.refresh(period)
    return period


async def get_stats(db: AsyncSession) -> PeriodStats:
    result = await db.execute(select(Period).order_by(Period.start_date.asc()))
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

    return PeriodStats(
        average_cycle_length=avg_cycle_length,
        average_period_length=avg_period_length,
        current_period=current,
        predicted_next_start=predicted,
    )
