"""add users table

Revision ID: 48f8a802a3c2
Revises: 2a6448cda015
Create Date: 2012-11-29 19:32:29.684531

"""

from datetime import datetime

# revision identifiers, used by Alembic.
revision = '48f8a802a3c2'
down_revision = '2a6448cda015'

from alembic import op
import sqlalchemy as sa

from tradeorsale.libs.models import ModelMixin


class AuditableModel(object):
    is_deleted = sa.Column(sa.Boolean, default=False)
    created = sa.Column(sa.DateTime, default=datetime.now)
    updated = sa.Column(sa.DateTime, nullable=True, default=None)


class User(AuditableModel):
    __tablename__ = "users"
    id = sa.Column(sa.Integer, primary_key=True)
    name = sa.Column(sa.String(50), nullable=False)
    email = sa.Column(sa.String(50), index=True, unique=True, nullable=False)
    password = sa.Column(sa.String(50), nullable=False)
    photo = sa.Column(sa.Text)


def upgrade():
    op.create_table(*ModelMixin.alembicfy_cols(User))


def downgrade():
    op.drop_table(User.__tablename__)
