"""song analysis: why a song failed, and the old failures are tried again

Almost the whole library failed with an older version of the analysis and was never tried again; the cause is gone.

Revision ID: b6d2f8a4c917
Revises: c4e8a1b7d350
Create Date: 2026-11-13
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "b6d2f8a4c917"
down_revision: str | Sequence[str] | None = "c4e8a1b7d350"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("track_vocals", sa.Column("error", sa.String(500), nullable=True))
    op.execute("DELETE FROM track_vocals WHERE failed")


def downgrade() -> None:
    op.drop_column("track_vocals", "error")
