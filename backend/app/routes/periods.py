import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas import PeriodCreate, PeriodEnd, PeriodResponse, PeriodStats
from app.services.period_service import (
    create_period,
    end_period,
    get_stats,
    list_periods,
)

router = APIRouter(prefix="/periods", tags=["periods"])


@router.get("", response_model=list[PeriodResponse])
async def get_periods(db: AsyncSession = Depends(get_db)):
    return await list_periods(db)


@router.post("", response_model=PeriodResponse, status_code=201)
async def start_period(
    body: PeriodCreate, db: AsyncSession = Depends(get_db)
):
    try:
        return await create_period(db, body.start_date)
    except ValueError as e:
        raise HTTPException(status_code=409, detail=str(e))


@router.patch("/{period_id}", response_model=PeriodResponse)
async def patch_period(
    period_id: int, body: PeriodEnd, db: AsyncSession = Depends(get_db)
):
    try:
        return await end_period(db, period_id, body.end_date)
    except LookupError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/stats", response_model=PeriodStats)
async def period_stats(db: AsyncSession = Depends(get_db)):
    return await get_stats(db)
