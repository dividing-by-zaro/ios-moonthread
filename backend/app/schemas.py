from datetime import date, datetime

from pydantic import BaseModel


class PeriodCreate(BaseModel):
    start_date: date


class PeriodEnd(BaseModel):
    end_date: date


class PeriodUpdate(BaseModel):
    start_date: date
    end_date: date | None = None


class PeriodResponse(BaseModel):
    id: int
    start_date: date
    end_date: date | None
    created_at: datetime

    model_config = {"from_attributes": True}


class PeriodStats(BaseModel):
    average_cycle_length: float | None
    average_period_length: float | None
    current_period: PeriodResponse | None
    predicted_next_start: date | None
