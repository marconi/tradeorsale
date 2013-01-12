"""added user_id field to items table

Revision ID: 6aa6141150d
Revises: 1dc2dc38940d
Create Date: 2012-12-06 07:17:02.918287

"""

# revision identifiers, used by Alembic.
revision = '6aa6141150d'
down_revision = '1dc2dc38940d'

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.add_column('items', sa.Column('user_id', sa.Integer,
        sa.ForeignKey('users.id'), nullable=False))
    op.execute("UPDATE items SET user_id = 1")


def downgrade():
    op.drop_column('items', 'user_id')
