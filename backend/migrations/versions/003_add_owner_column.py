"""create demo_periods table with seeded data

Revision ID: 003
Revises: 002
Create Date: 2026-02-10
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "003"
down_revision: Union[str, None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

DEMO_PERIODS = [
    ("2024-02-05", "2024-02-09"),
    ("2024-03-03", "2024-03-07"),
    ("2024-03-31", "2024-04-04"),
    ("2024-04-28", "2024-05-02"),
    ("2024-05-26", "2024-05-30"),
    ("2024-06-24", "2024-06-28"),
    ("2024-07-22", "2024-07-26"),
    ("2024-08-20", "2024-08-24"),
    ("2024-09-16", "2024-09-20"),
    ("2024-10-14", "2024-10-18"),
    ("2024-11-10", "2024-11-15"),
    ("2024-12-08", "2024-12-12"),
    ("2025-01-06", "2025-01-10"),
    ("2025-02-02", "2025-02-06"),
    ("2025-03-03", "2025-03-07"),
    ("2025-03-31", "2025-04-04"),
    ("2025-04-28", "2025-05-01"),
    ("2025-05-25", "2025-05-30"),
    ("2025-06-23", "2025-06-27"),
    ("2025-07-20", "2025-07-24"),
    ("2025-08-18", "2025-08-22"),
    ("2025-09-14", "2025-09-18"),
    ("2025-10-13", "2025-10-17"),
    ("2025-11-10", "2025-11-14"),
    ("2025-12-08", "2025-12-12"),
    ("2026-01-05", "2026-01-09"),
    ("2026-02-02", None),  # ongoing
]


def upgrade() -> None:
    op.create_table(
        "demo_periods",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
        ),
        sa.UniqueConstraint("start_date", name="uq_demo_periods_start_date"),
    )

    demo_table = sa.table(
        "demo_periods",
        sa.column("start_date", sa.Date),
        sa.column("end_date", sa.Date),
    )
    op.bulk_insert(
        demo_table,
        [{"start_date": start, "end_date": end} for start, end in DEMO_PERIODS],
    )


def downgrade() -> None:
    op.drop_table("demo_periods")
