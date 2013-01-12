"""add items quantity field

Revision ID: 45ef229fc2e2
Revises: 20716c1fcf3e
Create Date: 2012-11-22 18:11:07.524935

"""

# revision identifiers, used by Alembic.
revision = '45ef229fc2e2'
down_revision = '20716c1fcf3e'

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.add_column('items', sa.Column('quantity', sa.Integer, default=0))


def downgrade():
    op.drop_column('items', 'quantity')
