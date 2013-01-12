"""added traded_with field

Revision ID: 48dae7a093a7
Revises: 6aa6141150d
Create Date: 2012-12-14 05:14:20.250708

"""

# revision identifiers, used by Alembic.
revision = '48dae7a093a7'
down_revision = '6aa6141150d'

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.add_column('items', sa.Column('trade_with', sa.String(200)))


def downgrade():
    op.drop_column('items', 'trade_with')
