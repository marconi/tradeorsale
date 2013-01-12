# -*- coding: utf-8 -*-

import simplejson as json
from pyramid import testing

from tradeorsale.libs.models import DBSession
from tradeorsale.apps.dashboard.views import dashboard
from tradeorsale.apps.item.models import Item
from ..core import BaseTestCase


class DashboardViewsTest(BaseTestCase):

    def test_dashboard_view_drafts_empty(self):
        """
        Test that dashboard view returns empty list
        draft items when there are no draft items yet.
        """
        self._create_item_status()
        request = testing.DummyRequest()
        response = dashboard(request)
        draft_items = json.loads(response['draft_items'])
        self.assertEqual(draft_items, [])

    def test_dashboard_view_drafts_nonempty(self):
        """
        Test that dashboard view returns non-empty list
        draft items when there are draft items.
        """
        self._create_item_status()
        DBSession.add(Item(name='iPhone', type='TRADE',
            description='A smart phone.', status=self.draft_status, quantity=1))
        DBSession.add(Item(name='Macbook Pro', type='SALE',
            description='An apple product.', price=30500,
            status=self.ongoing_status, quantity=5))
        DBSession.commit()

        request = testing.DummyRequest()
        response = dashboard(request)
        draft_items = json.loads(response['draft_items'])

        self.assertEqual(len(draft_items), 1)
        self.assertNotEqual(draft_items, [])
