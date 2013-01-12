"""create items table

Revision ID: 7274b3abfd8
Revises: None
Create Date: 2012-11-22 16:53:48.206556

"""

from datetime import datetime

# revision identifiers, used by Alembic.
revision = '7274b3abfd8'
down_revision = None

from alembic import op
import sqlalchemy as sa
from sqlalchemy.orm import relationship, backref

from tradeorsale.libs.models import ModelMixin


class AuditableModel(object):
    is_deleted = sa.Column(sa.Boolean, default=False)
    created = sa.Column(sa.DateTime, default=datetime.now)
    updated = sa.Column(sa.DateTime, nullable=True, default=None)


class ItemStatus(object):
    __tablename__ = 'itemstatus'
    id = sa.Column(sa.Integer, primary_key=True)
    name = sa.Column(sa.String(20), unique=True, nullable=False)


class Item(AuditableModel):
    __tablename__ = 'items'
    id = sa.Column(sa.Integer, primary_key=True)
    name = sa.Column(sa.String(100), nullable=False)
    description = sa.Column(sa.Text, nullable=False)
    type = sa.Column(sa.Enum('TRADE', 'SALE', name='itemtype'), nullable=False)

    status_id = sa.Column(sa.Integer, sa.ForeignKey('itemstatus.id'))
    status = relationship("ItemStatus", innerjoin=True,
        backref=backref('items', order_by=name))

    price = sa.Column(sa.Numeric(10, 2), default=None)


def upgrade():
    item_status_cols = ModelMixin.alembicfy_cols(ItemStatus)

    op.create_table(*item_status_cols)
    op.create_table(*ModelMixin.alembicfy_cols(Item))

    op.bulk_insert(sa.sql.table(*item_status_cols),
        [{'id': 1, 'name': 'DRAFTS'},
         {'id': 2, 'name': 'ONGOING'},
         {'id': 3, 'name': 'ARCHIVED'}])


def downgrade():
    op.drop_table(Item.__tablename__)
    op.drop_table(ItemStatus.__tablename__)
    sa.Enum(name='itemtype').drop(op.get_bind(), checkfirst=False)
