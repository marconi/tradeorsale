# -*- coding: utf-8 -*-

import unittest
import importlib
from paste.deploy.loadwsgi import appconfig
from sqlalchemy import engine_from_config
from StringIO import StringIO
from PIL import Image

from pyramid import testing

from tradeorsale import settings
from tradeorsale.libs.models import initialize_db, Base, DBSession
from tradeorsale.apps.item.models import Item, ItemStatus


pyramid_settings = appconfig('config:test.ini', relative_to='.')


class BaseTestCase(unittest.TestCase):
    """
    A parent TestCase with the following enabled support:

    - database
    - settings
    - threadlocals
    - static file serving
    """

    def __init__(self, *args, **kwargs):
        super(BaseTestCase, self).__init__(*args, **kwargs)
        self.model_scanner()

        # cache the engine so it doesn't get recreated on every setup
        self.engine = engine_from_config(pyramid_settings, 'sqlalchemy.')

    def model_scanner(self):
        """
        Scans all apps for models and imports them so
        they can be found by sqlalchemy's metadata.
        """
        for app in settings.INSTALLED_APPS:
            importlib.import_module(app)

    def setUp(self):
        initialize_db(self.engine)
        Base.metadata.create_all()  # create all tables

        request = testing.DummyRequest()
        self.config = testing.setUp(request=request, settings=pyramid_settings)
        self.config.add_static_view('static', 'tradeorsale:static')
        self.config.testing_securitypolicy(userid='marc', permissive=True)

    def tearDown(self):
        testing.tearDown()

        # manually delete images path created by item because tearDown
        # disruptively drops table and no time to execute delete images event.
        self._remove_existing_items()

        DBSession.remove()
        Base.metadata.drop_all(self.engine)  # drop all tables

    def _create_item_status(self):
        """
        Helper method to create item statuses.
        """
        self.draft_status = ItemStatus('DRAFTS')
        self.ongoing_status = ItemStatus('ONGOING')
        self.archived_status = ItemStatus('ARCHIVED')
        DBSession.add(self.draft_status)
        DBSession.add(self.ongoing_status)
        DBSession.add(self.archived_status)
        DBSession.commit()

    def _remove_existing_items(self):
        """
        Helper method to remove existing items.
        """
        for item in DBSession.query(Item).all():
            DBSession.delete(item)
        DBSession.commit()


class MockFileImage(object):

    def __init__(self, file, filename='image.jpg'):
        self.file = StringIO()

        # create empty image and save it to file attribute
        Image.new("RGB", (5, 5), (255, 255, 255)).save(self.file, 'JPEG')

        self.file.seek(0)
        self.filename = filename
