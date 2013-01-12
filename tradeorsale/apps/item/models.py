# -*- coding: utf-8 -*-

import os
import shutil
import logging
import pkg_resources as pkgr
from sqlalchemy.event import listen
from sqlalchemy import (Column, Integer, String, Numeric, Text,
                        ForeignKey, Enum, DateTime)
from sqlalchemy.orm import relationship, backref

from pyramid.threadlocal import get_current_request

from tradeorsale.libs.models import Base, ModelMixin, AuditableModel
from tradeorsale.libs.helpers import assets_url
from tradeorsale.libs.utils import base36


logger = logging.getLogger('tradeorsale')

THUMBNAIL_SIZES = {
    'small': (52, 52),
    'medium': (254, 254)
}


class ItemStatus(Base, ModelMixin):
    __tablename__ = "itemstatus"
    id = Column(Integer, primary_key=True)
    name = Column(String(20), index=True, unique=True)

    def __init__(self, name):
        self.name = name

    def __repr__(self):
        return "<ItemStatus %r>" % self.name


class ItemImage(Base, ModelMixin):
    __tablename__ = "itemimages"
    id = Column(Integer, primary_key=True)
    name = Column(String(50))
    path = Column(Text)

    item_id = Column(Integer, ForeignKey('items.id'), index=True)
    item = relationship("Item", innerjoin=True,
        backref=backref('images', lazy='dynamic',
            cascade="all, delete, delete-orphan"))

    parent_id = Column(Integer, ForeignKey('itemimages.id'), index=True)
    subimages = relationship("ItemImage", lazy='dynamic',
        cascade="all, delete, delete-orphan",
        backref=backref('parent', remote_side=[id]))

    size = Column(String(20), default='original')

    def __init__(self, item, name, path, size='original', parent=None):
        self.item = item
        self.name = name
        self.path = path
        self.size = size
        if parent:
            self.parent = parent

    def __repr__(self):
        return "<ItemImage %r>" % self.name

    def get_resized_image(self, size):
        """
        Returns url for resized image specified by `size`.
        """
        raw_filename, ext = os.path.splitext(self.name)
        resized_filename = '%s_%s%s' % (raw_filename, size, ext)
        return os.path.join(os.path.dirname(self.path), resized_filename)

    @classmethod
    def delete_image(cls, mapper, connection, target):
        static_path = pkgr.resource_filename('tradeorsale', 'static')
        image_path = os.path.join('items/images', str(target.item_id), target.name)
        image_abspath = os.path.join(static_path, image_path)
        logger.info("deleting image: %s" % image_abspath)
        try:
            os.remove(image_abspath)
        except OSError:
            pass

listen(ItemImage, 'after_delete', ItemImage.delete_image)


class Item(Base, ModelMixin, AuditableModel):
    __tablename__ = 'items'
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    description = Column(Text)
    type = Column(Enum('TRADE', 'SALE', name='itemtype'))

    trade_with = Column(String(200))

    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    user = relationship("User", innerjoin=True,
        backref=backref('items', lazy='dynamic',
            cascade="all, delete, delete-orphan"))

    status_id = Column(Integer, ForeignKey('itemstatus.id'), index=True)
    status = relationship("ItemStatus", innerjoin=True,
        backref=backref('items', order_by=name))

    price = Column(Numeric(10, 2), default=None)
    quantity = Column(Integer, default=0)
    original_quantity = Column(Integer, default=0)
    reason = Column(String(100))

    # traded-on/sold-on date
    transaction_date = Column(DateTime, default=None)

    def __init__(self, user, name, type, quantity, description, status,
        price=None, trade_with=None, reason=None):
        self.user = user
        self.name = name
        self.type = type
        self.trade_with = trade_with
        self.price = price
        self.quantity = quantity
        self.description = description
        self.status = status

        # if this is a new item, set original_quantity to  quantity
        if not self.id:
            self.original_quantity = self.quantity

        if reason:
            self.reason = reason

    def __repr__(self):
        return "<Item %d:%r>" % (self.id, self.name)

    def to_dict(self):
        """
        Overrides parent to_dict method to
        convert images relationship to dict.
        """
        fields = super(Item, self).to_dict()
        fields['images'] = []
        if self.images.count() > 0:
            request = get_current_request()
            for image in self.images.filter_by(size='original'):
                image_sizes = {
                    'id': image.id,
                    'original': assets_url(request, image.path)}
                for size in THUMBNAIL_SIZES.keys():
                    image_sizes[size] = assets_url(
                        request, image.get_resized_image(size))
                fields['images'].append(image_sizes)

        # normalize price
        fields['price'] = str(fields['price']) if fields['price'] else ''

        # backbone view mode doesn't understand status_id,
        # so we switch it back to is_draft with the right value.
        fields['is_draft'] = True if self.status.name == 'DRAFTS' else False
        del fields['status_id']

        # convert tags to flat dict
        fields['tags'] = [tag.to_dict() for tag in self.tags]

        # add base36 encoded id
        if fields.get('id', None):
            fields['id_b36'] = base36.encode(fields['id'])

        return fields

    @classmethod
    def create_images_path(cls, mapper, connection, target):
        static_path = pkgr.resource_filename('tradeorsale', 'static')
        item_images_abspath = os.path.join(static_path,
            os.path.join('items/images', str(target.id)))

        # create item's image path if it doesn't exist yet
        if not os.path.exists(item_images_abspath):
            logger.info("creating image path: %s" % item_images_abspath)
            os.makedirs(item_images_abspath)

    @classmethod
    def delete_images_path(cls, mapper, connection, target):
        static_path = pkgr.resource_filename('tradeorsale', 'static')
        item_images_path = os.path.join('items/images', str(target.id))
        item_images_abspath = os.path.join(static_path, item_images_path)
        logger.info("deleting images of item: %s" % item_images_abspath)
        try:
            shutil.rmtree(item_images_abspath)
        except OSError as e:
            logger.error("error deleting images: %s" % str(e))

listen(Item, 'after_insert', Item.create_images_path)
listen(Item, 'after_delete', Item.delete_images_path)


class ItemTag(Base, ModelMixin):
    __tablename__ = "itemtags"
    id = Column(Integer, primary_key=True)
    name = Column(String(50), index=True)
    items = relationship("Item", secondary="itemtags_assoc", backref="tags")

    def __init__(self, name):
        self.name = name

    def __repr__(self):
        return "<ItemTag %r>" % self.name


class ItemTagAssoc(Base):
    __tablename__ = "itemtags_assoc"
    item_id = Column(Integer, ForeignKey('items.id'), index=True, primary_key=True)
    tag_id = Column(Integer, ForeignKey('itemtags.id'), index=True, primary_key=True)
