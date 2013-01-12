"""add items reason field

Revision ID: 2996c895d6e8
Revises: 7274b3abfd8
Create Date: 2012-11-22 17:59:31.674816

"""

# revision identifiers, used by Alembic.
revision = '2996c895d6e8'
down_revision = '7274b3abfd8'

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.add_column('items', sa.Column('reason', sa.String(100)))


def downgrade():
    op.drop_column('items', 'reason')
