# -*- coding: utf-8 -*-

import os
import pkg_resources as pkgr

from tradeorsale.libs.models import DBSession
from tradeorsale.apps.item.models import Item, ItemImage
from ..core import BaseTestCase, MockFileImage


class ItemModelTest(BaseTestCase):

    def test_create_image_path(self):
        """
        Test that creating an item creates image path.
        """
        self._create_item_status()
        item = Item(name='iPhone', type='TRADE', quantity=1,
            description='A smart phone', status=self.draft_status,
            reason='just because')
        DBSession.add(item)
        DBSession.commit()

        # check that the images path has been created
        images_path = pkgr.resource_filename('tradeorsale', 'static')
        item_images_abspath = os.path.join(images_path,
            os.path.join('items/images', str(item.id)))
        self.failUnless(os.path.exists(item_images_abspath))

    def test_delete_image_path(self):
        """
        Test that deleting an item deletes image path.
        """
        self._create_item_status()
        item = Item(name='iPhone', type='TRADE', quantity=1,
            description='A smart phone', status=self.draft_status,
            reason='just because')
        DBSession.add(item)
        DBSession.commit()

        DBSession.delete(item)
        DBSession.commit()

        # check that the images path has been created
        images_path = pkgr.resource_filename('tradeorsale', 'static')
        item_images_abspath = os.path.join(images_path,
            os.path.join('items/images', str(item.id)))
        self.failUnless(not os.path.exists(item_images_abspath))


class ItemImageModelTest(BaseTestCase):

    def test_delete_image(self):
        """
        Test that deleting an image deletes it from disk.
        """
        # create item first
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

        # delete image and check that it doesn't exist
        DBSession.delete(item_image)
        DBSession.commit()
        self.failUnless(not os.path.exists(image_path))
