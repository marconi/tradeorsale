"""add transaction_date and original_quantity fields on items

Revision ID: 1dc2dc38940d
Revises: 44cc0847efda
Create Date: 2012-12-04 15:23:25.668437

"""

# revision identifiers, used by Alembic.
revision = '1dc2dc38940d'
down_revision = '44cc0847efda'

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.add_column('items', sa.Column('transaction_date', sa.DateTime, default=None))
    op.add_column('items', sa.Column('original_quantity', sa.Integer, default=0))
    op.execute("UPDATE items SET original_quantity = quantity")


def downgrade():
    op.drop_column('items', 'transaction_date')
    op.drop_column('items', 'original_quantity')
