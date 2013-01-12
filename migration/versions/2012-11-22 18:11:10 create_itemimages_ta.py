"""create itemimages table

Revision ID: 20716c1fcf3e
Revises: 2996c895d6e8
Create Date: 2012-11-22 18:07:10.087788

"""

from datetime import datetime

# revision identifiers, used by Alembic.
revision = '20716c1fcf3e'
down_revision = '2996c895d6e8'

from alembic import op
import sqlalchemy as sa
from sqlalchemy.orm import relationship, backref

from tradeorsale.libs.models import ModelMixin


class AuditableModel(object):
    is_deleted = sa.Column(sa.Boolean, default=False)
    created = sa.Column(sa.DateTime, default=datetime.now)
    updated = sa.Column(sa.DateTime, nullable=True, default=None)


class ItemImage(AuditableModel):
    __tablename__ = "itemimages"
    id = sa.Column(sa.Integer, primary_key=True)
    name = sa.Column(sa.String(50))
    path = sa.Column(sa.Text)

    item_id = sa.Column(sa.Integer, sa.ForeignKey('items.id'))
    item = relationship("Item", innerjoin=True,
        backref=backref('images', lazy='dynamic',
            cascade="all, delete, delete-orphan"))


def upgrade():
    item_images_cols = ModelMixin.alembicfy_cols(ItemImage)
    op.create_table(*item_images_cols)


def downgrade():
    op.drop_table(ItemImage.__tablename__)
