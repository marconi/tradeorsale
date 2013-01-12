"""removed auditing fields from ItemImage

Revision ID: 44cc0847efda
Revises: 48f8a802a3c2
Create Date: 2012-11-29 20:16:52.127835

"""

from datetime import datetime

# revision identifiers, used by Alembic.
revision = '44cc0847efda'
down_revision = '48f8a802a3c2'

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.drop_column('itemimages', 'created')
    op.drop_column('itemimages', 'updated')
    op.drop_column('itemimages', 'is_deleted')


def downgrade():
    op.add_column('itemimages', sa.Column('created', sa.DateTime, default=datetime.now))
    op.add_column('itemimages', sa.Column('updated', sa.DateTime, nullable=True, default=None))
    op.add_column('itemimages', sa.Column('is_deleted', sa.Boolean, default=False))
