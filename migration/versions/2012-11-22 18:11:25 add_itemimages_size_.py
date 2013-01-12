"""add itemimages size field

Revision ID: 2778fa1d5108
Revises: 45ef229fc2e2
Create Date: 2012-11-22 18:18:25.273962

"""

# revision identifiers, used by Alembic.
revision = '2778fa1d5108'
down_revision = '45ef229fc2e2'

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.add_column('itemimages', sa.Column('size', sa.String(20), default='original'))


def downgrade():
    op.drop_column('itemimages', 'size')
