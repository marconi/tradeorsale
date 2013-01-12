# -*- coding: utf-8 -*-

import os
import logging
import pkg_resources as pkgr
from sqlalchemy import Column, Integer, String, Text
from sqlalchemy.event import listen
from PIL import Image, ImageOps

from tradeorsale.libs.models import Base, ModelMixin, AuditableModel


PHOTO_SIZES = {
    'small': (40, 40),
    'medium': (160, 160)
}

logger = logging.getLogger('tradeorsale')


class User(Base, ModelMixin, AuditableModel):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    name = Column(String(50), nullable=False)
    email = Column(String(50), index=True, unique=True, nullable=False)
    password = Column(String(50), nullable=False)
    photo = Column(Text)

    def __init__(self, name, email, password, photo=None):
        self.name = name
        self.email = email
        self.password = password
        if photo:
            self.photo = photo

    def __repr__(self):
        return "<User %r>" % self.name

    def get_resized_photo(self, size):
        """
        Returns url for resized photo specified by `size`.
        """
        if not self.photo:
            return None

        static_path = pkgr.resource_filename('tradeorsale', 'static')
        raw_filename, ext = os.path.splitext(os.path.basename(self.photo))
        resized_filename = '%s_%s%s' % (raw_filename, size, ext)
        resized_uri = os.path.join(os.path.dirname(self.photo), resized_filename)
        resize_path = os.path.join(static_path, resized_uri[1:])

        # if we have a resized file, return it immediately
        if os.path.exists(resize_path):
            return resized_uri

        # else, try generating a resized image
        original_path = os.path.join(static_path, self.photo[1:])
        try:
            img = Image.open(original_path)
        except IOError as e:
            logger.error("unable to open photo: %s" % str(e))
            return None

        resized_img = ImageOps.fit(img, PHOTO_SIZES[size], Image.ANTIALIAS)
        resized_img.save(resize_path, quality=90, optimize=True)
        return resized_uri

    @classmethod
    def resize_photo(cls, mapper, connection, target):
        pass

listen(User, 'after_insert', User.resize_photo)

# TODO: upon insert of user, if there's a photo, resize it.
