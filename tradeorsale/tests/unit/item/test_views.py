# -*- coding: utf-8 -*-

import os
import uuid
import simplejson as json
from redis import StrictRedis
import pkg_resources as pkgr
from StringIO import StringIO

from pyramid import testing
from pyramid.request import Request
from pyramid.httpexceptions import HTTPBadRequest

from tradeorsale.libs.models import DBSession
from tradeorsale.apps.item.views import items, upload_item_images, item_images
from tradeorsale.apps.item.models import Item, ItemImage
from ..core import BaseTestCase, MockFileImage, pyramid_settings


class ItemViewsTest(BaseTestCase):

    def __init__(self, *args, **kwargs):
        super(ItemViewsTest, self).__init__(*args, **kwargs)
        self.redis = StrictRedis(
            host=pyramid_settings['redis.host'],
            port=int(pyramid_settings['redis.port']),
            db=int(pyramid_settings['redis.db']))

    def setUp(self):
        super(ItemViewsTest, self).setUp()
        self.config.registry.redis = self.redis

    def test_items_post(self):
        """
        Test creation of new item by POSTing.
        """
        payload = {"name": "Macbook Air", "type": "TRADE", "quantity": "1",
                   "price": "", "description": "Lightweight lappy.",
                   "reason": "", "is_draft": "y", "uuid": str(uuid.uuid4())}

        request = Request({}, method='POST', body=json.dumps(payload))
        request.registry = self.config.registry

        response = items(request)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(DBSession.query(Item).count(), 1)

    def test_items_post_failed(self):
        """
        Test that when POSTing malformed payload, it'll raise HTTPBadRequest.
        """
        payload = {"name": "", "type": "", "quantity": "",
                   "price": "", "description": "", "reason": "",
                   "is_draft": "", "uuid": ""}

        request = Request({}, method='POST', body=json.dumps(payload))
        request.registry = self.config.registry

        self.assertRaises(HTTPBadRequest, items, request)
        self.assertEqual(DBSession.query(Item).count(), 0)

    def test_items_put(self):
        """
        Test updating an item.
        """
        self._create_item_status()

        payload = {"name": "Macbook Air", "type": "TRADE", "quantity": "1",
                   "price": "", "description": "Lightweight lappy.",
                   "reason": "", "is_draft": "y", "uuid": str(uuid.uuid4())}

        request = Request({}, method='POST', body=json.dumps(payload))
        request.registry = self.config.registry

        # make the request
        items(request)

        # try retrieving the newly added item
        item = DBSession.query(Item).first()
        self.failUnless(item)

        payload = {"name": "Macbook Pro", "type": "SALE", "quantity": "5",
                   "price": "200.00", "description": "Lightweight lappy.",
                   "reason": "", "is_draft": "n", "id": item.id}

        request.matchdict = {'id': item.id}
        request.method = 'PUT'
        request.body = json.dumps(payload)

        # make the request again
        response = items(request)
        self.assertEqual(response.status_code, 200)

        # reload item
        item = DBSession.query(Item).filter_by(id=item.id).first()
        self.assertEqual(item.name, payload['name'])
        self.assertEqual(item.type, payload['type'])
        self.assertEqual(item.quantity, int(payload['quantity']))
        self.assertEqual(str(item.price), payload['price'])
        self.assertEqual(item.status_id, self.draft_status.id)

    def test_items_put_failed(self):
        """
        Test that updating non-existent item fails.
        """
        payload = {"name": "Macbook Pro", "type": "SALE", "quantity": "5",
                   "price": "200.00", "description": "Lightweight lappy.",
                   "reason": "", "is_draft": "n", "id": 1}

        request = Request({}, method='PUT', body=json.dumps(payload))
        request.registry = self.config.registry
        request.matchdict = {'id': 1}
        request.method = 'PUT'

        self.assertRaises(HTTPBadRequest, items, request)
        self.assertEqual(DBSession.query(Item).count(), 0)

    def test_items_delete(self):
        """
        Test deleting an item.
        """
        # first create an item
        self._create_item_status()
        payload = {"name": "Macbook Air", "type": "TRADE", "quantity": "1",
                   "price": "", "description": "Lightweight lappy.",
                   "reason": "", "is_draft": "y", "uuid": str(uuid.uuid4())}

        request = Request({}, method='POST', body=json.dumps(payload))
        request.registry = self.config.registry

        response = items(request)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(DBSession.query(Item).count(), 1)

        # try retrieving the newly added item
        item = DBSession.query(Item).first()

        # now send a delete request
        request.method = 'DELETE'
        request.matchdict = {'id': item.id}
        request.body = None
        items(request)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(DBSession.query(Item).count(), 0)

    def test_upload_item_images_post_uuid(self):
        """
        Test posting images for an item via uuid.
        """
        self._create_item_status()
        item = Item(name='iPhone', type='TRADE', quantity=1,
            description='A smart phone', status=self.draft_status,
            reason='just because')
        DBSession.add(item)
        DBSession.commit()

        item_uuid = str(uuid.uuid4())
        mock_image = MockFileImage('image1.png')

        # write to disk the dummy image so the view can resize it
        original = '%s.png' % item_uuid
        static_path = pkgr.resource_filename('tradeorsale', 'static')
        image_path = os.path.join(static_path,
            os.path.join('items/images', str(item.id)), original)
        with open(image_path, 'wb') as handle:
            handle.write(mock_image.file.read())
        self.failUnless(os.path.exists(image_path))

        # build request
        mock_image.file.seek(0)
        payload = {"uuid": item_uuid, "image": mock_image}
        request = testing.DummyRequest(post=payload)
        request.registry = self.config.registry

        # set a dummy uuid to regis
        self.redis.hset('item_uuid_to_id', item_uuid, item.id)
        self.redis.expire(item_uuid, 3600)

        response = upload_item_images(request)
        self.assertEqual(response.status_code, 200)

        # test that there are 3 images: original, small and medium
        self.assertEqual(DBSession.query(ItemImage).filter_by(item_id=item.id).count(), 3)

    def test_upload_item_images_post_uuid_failed(self):
        """
        Test posting images for an item via uuid with invalid image fails.
        """
        self._create_item_status()
        item = Item(name='iPhone', type='TRADE', quantity=1,
            description='A smart phone', status=self.draft_status,
            reason='just because')
        DBSession.add(item)
        DBSession.commit()

        class DumbMockImage(object):
            file = StringIO('image')
            filename = 'image1.jpg'

        item_uuid = str(uuid.uuid4())
        mock_image = DumbMockImage()

        payload = {"uuid": item_uuid, "image": mock_image}
        request = testing.DummyRequest(post=payload)
        request.registry = self.config.registry

        # set a dummy uuid to regis
        self.redis.hset('item_uuid_to_id', item_uuid, item.id)
        self.redis.expire(item_uuid, 3600)

        self.assertRaises(HTTPBadRequest, upload_item_images, request)

    def test_upload_item_images_post_id(self):
        """
        Test posting images for an item via id.
        """
        self._create_item_status()
        item = Item(name='iPhone', type='TRADE', quantity=1,
            description='A smart phone', status=self.draft_status,
            reason='just because')
        DBSession.add(item)
        DBSession.commit()

        uuid_filename = str(uuid.uuid4())
        mock_image = MockFileImage('image1.png')

        # write to disk the dummy image so the view can resize it
        original = '%s.png' % uuid_filename
        static_path = pkgr.resource_filename('tradeorsale', 'static')
        image_path = os.path.join(static_path,
            os.path.join('items/images', str(item.id)), original)
        with open(image_path, 'wb') as handle:
            handle.write(mock_image.file.read())
        self.failUnless(os.path.exists(image_path))

        # build request
        mock_image.file.seek(0)
        payload = {"item_id": item.id, "image": mock_image}
        request = testing.DummyRequest(post=payload)
        request.registry = self.config.registry

        response = upload_item_images(request)
        self.assertEqual(response.status_code, 200)

        # test that there are 3 images: original, small and medium
        self.assertEqual(DBSession.query(ItemImage).filter_by(item_id=item.id).count(), 3)

    def test_item_image_delete(self):
        """
        Test that image is deleted when DELETE request is sent.
        """
        self._create_item_status()
        item = Item(name='iPhone', type='TRADE', quantity=1,
            description='A smart phone', status=self.draft_status,
            reason='just because')
        DBSession.add(item)
        DBSession.commit()

        # write to disk the dummy image
        mock_image = MockFileImage('original.jpg')
        static_path = pkgr.resource_filename('tradeorsale', 'static')
        item_images_path = os.path.join(static_path,
            os.path.join('items/images', str(item.id)))
        image_path = os.path.join(item_images_path, mock_image.filename)
        with open(image_path, 'wb') as handle:
            handle.write(mock_image.file.read())
        self.failUnless(os.path.exists(image_path))

        # save the image in db
        item_image = ItemImage(item.id, mock_image.filename,
            os.path.join('/%s' % item_images_path, mock_image.filename))
        DBSession.add(item_image)
        DBSession.commit()

        # send DELETE request
        request = Request({}, method='DELETE')
        request.matchdict = {'id': item.id}
        request.registry = self.config.registry

        # check that record was deleted
        response = item_images(None, request)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(DBSession.query(ItemImage).count(), 0)
        self.failUnless(not os.path.exists(image_path))

    def test_item_image_delete_fail(self):
        """
        Test deletion of non-existent image via DELETE request.
        """
        # send DELETE request
        request = Request({}, method='DELETE')
        request.matchdict = {'id': 1}
        request.registry = self.config.registry

        self.assertRaises(HTTPBadRequest, item_images, None, request)
