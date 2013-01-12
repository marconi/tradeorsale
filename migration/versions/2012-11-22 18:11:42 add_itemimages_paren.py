"""add itemimages parent_id field

Revision ID: 4a80cf3a2caa
Revises: 2778fa1d5108
Create Date: 2012-11-22 18:22:42.899912

"""

# revision identifiers, used by Alembic.
revision = '4a80cf3a2caa'
down_revision = '2778fa1d5108'

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.add_column('itemimages', sa.Column('parent_id', sa.Integer, sa.ForeignKey('itemimages.id')))


def downgrade():
    op.drop_column('itemimages', 'parent_id')
