"""add index on some tables

Revision ID: 2a6448cda015
Revises: 195cc2743113
Create Date: 2012-11-26 06:19:25.577128

"""

# revision identifiers, used by Alembic.
revision = '2a6448cda015'
down_revision = '195cc2743113'

from alembic import op
import sqlalchemy as sa


def upgrade():
    # itemstatus
    op.create_index('ix_itemstatus_name', 'itemstatus', ['name'])

    # itemimages
    op.create_index('ix_itemimages_item_id', 'itemimages', ['item_id'])
    op.create_index('ix_itemimages_parent_id', 'itemimages', ['parent_id'])

    # itemcomments
    op.create_index('ix_itemcomments_item_id', 'itemimages', ['item_id'])

    # items
    op.create_index('ix_items_status_id', 'items', ['status_id'])

    # itemtags
    op.create_index('ix_itemtags_name', 'itemtags', ['name'])

    # itemtags_assoc
    op.create_index('ix_itemtags_assoc_item_id', 'itemtags_assoc', ['item_id'])
    op.create_index('ix_itemtags_assoc_tag_id', 'itemtags_assoc', ['tag_id'])


def downgrade():
    # itemstatus
    op.drop_index('ix_itemstatus_name', 'itemstatus')

    # itemimages
    op.drop_index('ix_itemimages_item_id', 'itemimages')
    op.drop_index('ix_itemimages_parent_id', 'itemimages')

    # itemcomments
    op.drop_index('ix_itemcomments_item_id', 'itemimages')

    # items
    op.drop_index('ix_items_status_id', 'items')

    # itemtags
    op.drop_index('ix_itemtags_name', 'itemtags')

    # itemtags_assoc
    op.drop_index('ix_itemtags_assoc_item_id', 'itemtags_assoc')
    op.drop_index('ix_itemtags_assoc_tag_id', 'itemtags_assoc')
