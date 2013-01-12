# -*- coding: utf-8 -*-

import logging
import simplejson as json

from pyramid.view import view_config

from tradeorsale.libs.models import DBSession
from tradeorsale.libs.json import JSONEncoder
from tradeorsale.apps.item.models import Item, ItemStatus


logger = logging.getLogger('tradeorsale')
json_header = {'Content-Type': 'application/json'}

PANEL_DEFAULT_PAGING = 10


def _items_to_json(items_iter):
    """
    Helper function that returns iterable items to json string.
    """
    items = [item.to_dict() for item in items_iter]
    return json.dumps(items, cls=JSONEncoder, use_decimal=True)


@view_config(route_name='dashboard', renderer='dashboard/dashboard.mako',
             permission='view')
def dashboard(request):
    draft, ongoing, archived = DBSession.query(
        ItemStatus).order_by(ItemStatus.id.asc()).all()

    # load draft items
    draft_items = DBSession.query(Item).filter_by(
        status=draft).order_by(Item.id.desc()).limit(PANEL_DEFAULT_PAGING)
    draft_items_json = _items_to_json(draft_items)

    # load ongoing items
    ongoing_items = DBSession.query(Item).filter_by(
        status=ongoing).order_by(Item.id.desc()).limit(PANEL_DEFAULT_PAGING)
    ongoing_items_json = _items_to_json(ongoing_items)

    # load archived items
    archived_items = DBSession.query(Item).filter_by(
        status=archived).order_by(Item.id.desc()).limit(PANEL_DEFAULT_PAGING)
    archived_items_json = _items_to_json(archived_items)

    return {'draft_items': draft_items_json,
            'ongoing_items': ongoing_items_json,
            'archived_items': archived_items_json,
            'body_class': 'plain-content'}
