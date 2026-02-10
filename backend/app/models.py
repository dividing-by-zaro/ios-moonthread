import datetime

from sqlalchemy import Date, DateTime, Integer, String, UniqueConstraint, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class Period(Base):
    __tablename__ = "periods"
    __table_args__ = (
        UniqueConstraint("owner", "start_date", name="uq_periods_owner_start_date"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    start_date: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    end_date: Mapped[datetime.date | None] = mapped_column(Date, nullable=True)
    owner: Mapped[str] = mapped_column(
        String(10), default="user", server_default="user", nullable=False
    )
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
