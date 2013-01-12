"""add items tags field

Revision ID: 195cc2743113
Revises: 4a80cf3a2caa
Create Date: 2012-11-24 20:20:08.843963

"""

# revision identifiers, used by Alembic.
revision = '195cc2743113'
down_revision = '4a80cf3a2caa'

from alembic import op
import sqlalchemy as sa
from sqlalchemy.orm import relationship

from tradeorsale.libs.models import ModelMixin


class ItemTagAssoc(object):
    __tablename__ = "itemtags_assoc"
    item_id = sa.Column(sa.Integer, sa.ForeignKey('items.id'), primary_key=True)
    tag_id = sa.Column(sa.Integer, sa.ForeignKey('itemtags.id'), primary_key=True)


class ItemTag(object):
    __tablename__ = "itemtags"
    id = sa.Column(sa.Integer, primary_key=True)
    name = sa.Column(sa.String(50))
    items = relationship("Item", secondary="itemtags_assoc", backref="tags")


def upgrade():
    op.create_table(*ModelMixin.alembicfy_cols(ItemTag))
    op.create_table(*ModelMixin.alembicfy_cols(ItemTagAssoc))


def downgrade():
    op.drop_table(ItemTagAssoc.__tablename__)
    op.drop_table(ItemTag.__tablename__)
