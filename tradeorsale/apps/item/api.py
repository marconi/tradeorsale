# -*- coding: utf-8 -*-

import os
import uuid
import logging
import shutil
from datetime import datetime
import pkg_resources as pkgr
from webob.multidict import MultiDict
from cornice.resource import resource, view
from sqlalchemy.orm.exc import NoResultFound
from PIL import Image, ImageOps

from pyramid.i18n import TranslationString as _

from tradeorsale.apps.user.models import User
from tradeorsale.apps.item.models import (Item, ItemStatus, ItemTag, ItemImage,
                                          THUMBNAIL_SIZES)
from tradeorsale.apps.item.forms import ItemForm
from tradeorsale.libs.models import DBSession
from tradeorsale.libs.helpers import flatten_form_errors, assets_url


API_VERSION = 'v1'
DEFAULT_OFFSET = 0
DEFAULT_LIMIT = 10

logger = logging.getLogger('tradeorsale')


class BaseService(object):
    """
    Base service that holds common validators.
    """

    def __init__(self, request):
        self.request = request

    ## validators

    def validate_paging(self, request):
        PAGING_DEFAULTS = {'offset': DEFAULT_OFFSET, 'limit': DEFAULT_LIMIT}
        for element in ('offset', 'limit'):
            try:
                int(request.GET.get(element, PAGING_DEFAULTS.get(element)))
            except ValueError:
                request.errors.add('url', element, _(u'Invalid %s') % element)

    def validate_user(self, request):
        try:
            user_id = int(request.matchdict['user_id'])
            try:
                DBSession.query(User).filter_by(id=user_id).one()
            except NoResultFound:
                request.errors.add('url', 'user_id', _(u"User doesn't exist"))
        except ValueError:
            request.errors.add('url', 'user_id', _(u'Invalid User ID'))

    def validate_item(self, request):
        try:
            user_id = int(request.matchdict['user_id'])
            item_id = int(request.matchdict['item_id'])
            try:
                DBSession.query(Item).filter_by(id=item_id, user_id=user_id).one()
            except NoResultFound:
                request.errors.add('url', 'item_id', _(u"Item doesn't exist"))
        except ValueError:
            request.errors.add('url', 'item_id', _(u'Invalid Item ID'))

    ## helper methods

    def page_queryset(self, queryset):
        offset = int(self.request.GET.get('offset', DEFAULT_OFFSET))
        limit = int(self.request.GET.get('limit', DEFAULT_LIMIT))

        # compute offset
        offset = offset - 1 if offset > 0 else offset
        offset = offset * limit
        limit += offset

        return queryset[offset:limit]


@resource(
    collection_path='/%s/users/{user_id}/items' % API_VERSION,
    path='/%s/users/{user_id}/items/{item_id}' % API_VERSION,
    renderer='smartjson',
    validators=('validate_user',))
class ItemService(BaseService):

    @view(validators=('validate_paging', 'validate_status'))
    def collection_get(self):
        """
        GET method for items collection, supports the following features:
        - item status filters
        - show more pagination
        """
        last_item_id = int(self.request.GET.get('last', 0))
        status_name = self.request.GET.get('status', None)

        # fetch user
        user_id = int(self.request.matchdict['user_id'])
        user = DBSession.query(User).filter_by(id=user_id).one()

        # filter status
        items = user.items
        if status_name:
            logger.info("filtering by status: %s" % status_name)
            status = DBSession.query(ItemStatus).filter_by(
                name=status_name.upper()).one()
            items = items.filter_by(status=status)

        # apply last item filtering if it exists
        if last_item_id:
            logger.info("filtering by last item id: %s" % last_item_id)
            items = items.filter(Item.id < last_item_id)

        # apply ordering
        items = items.order_by(Item.id.desc()).limit(DEFAULT_LIMIT)

        return [item.to_dict() for item in items]

    @view(validators=('validate_posted_item',))
    def collection_post(self):
        payload = MultiDict(self.request.json_body)

        # fetch user
        # TODO: assign currently logged-in user's id
        user = DBSession.query(User).filter_by(id=1).one()

        # fetch status
        status_name = 'DRAFTS' if payload.get('is_draft', False) else 'ONGOING'
        status = DBSession.query(ItemStatus).filter_by(name=status_name).one()

        qty = int(payload.get('quantity', 1))
        price = payload['price'] if payload.get('price', None) and payload['price'] else None
        new_item = Item(user=user,
                        name=payload['name'],
                        type=payload['type'],
                        trade_with=payload.get('trade_with', None),
                        status=status,
                        price=price,
                        quantity=qty,
                        description=payload['description'],
                        reason=payload['reason'])

        # load assigned tags and extend new item's tags
        if payload.get('tags', None):
            tag_ids = [tag['id'] for tag in payload['tags'] if tag.get('id', None)]
            tags = DBSession.query(ItemTag).filter(ItemTag.id.in_(tag_ids)).all()
            new_item.tags.extend(tags)

        DBSession.add(new_item)
        DBSession.commit()

        return new_item.to_dict()

    @view(validators=('validate_item',))
    def get(self):
        """
        GET method for fetching single item.
        """
        action = self.request.GET.get('action', None)
        item_id = int(self.request.matchdict['item_id'])
        item = DBSession.query(Item).filter_by(id=item_id).one()

        if action and action == 'clone':
            logger.info("cloning item: %s" % str(item_id))
            draft_status = DBSession.query(
                ItemStatus).filter_by(name='DRAFTS').one()
            cloned_item = Item(user=item.user,
                               name='%s - copy' % item.name,
                               type=item.type,
                               quantity=item.quantity,
                               description=item.description,
                               status=draft_status,
                               price=item.price,
                               reason=item.reason)
            cloned_item.tags = item.tags
            DBSession.add(cloned_item)
            DBSession.commit()

            # clone images
            static_path = pkgr.resource_filename('tradeorsale', 'static')
            source = os.path.join(static_path, 'items/images/%s' % item_id)
            destination = os.path.join(static_path, 'items/images/%s' % cloned_item.id)

            try:
                for imgfile in os.listdir(source):
                    shutil.copy(os.path.join(source, imgfile), destination)
                for image in item.images.filter_by(parent=None).all():
                    segments = image.path.split('/')
                    segments[3] = str(cloned_item.id)
                    original_img = ItemImage(item=cloned_item,
                                             name=image.name,
                                             path='/'.join(segments))
                    for subimage in image.subimages.all():
                        segments = subimage.path.split('/')
                        segments[3] = str(cloned_item.id)
                        sub_img = ItemImage(item=cloned_item,
                                            name=subimage.name,
                                            path='/'.join(segments),
                                            size=subimage.size,
                                            parent=original_img)
                        DBSession.add(sub_img)
                    DBSession.add(original_img)
            except OSError as e:
                logger.error("error while cloning images: %s" % str(e))

            DBSession.commit()
            return cloned_item.to_dict()

        return item.to_dict()

    @view(validators=('validate_item', 'validate_posted_item'))
    def put(self):
        item_id = int(self.request.matchdict['item_id'])
        payload = MultiDict(self.request.json_body)
        item = DBSession.query(Item).filter_by(id=item_id).one()
        transaction_date = None

        print payload

        # fetch status
        if payload.get('is_draft', False):
            status_name = 'DRAFTS'
        elif payload.get('status', None) and payload['status'] == 'archived':
            status_name = 'ARCHIVED'
            transaction_date = datetime.now()
        else:
            status_name = 'ONGOING'
        status = DBSession.query(ItemStatus).filter_by(name=status_name).one()

        # fetch new tags
        new_tags = []
        ids_to_add = [int(tag['id']) for tag in payload.get('tags', []) if tag.get('id', None)]
        if ids_to_add:
            new_tags.extend(DBSession.query(ItemTag).filter(
                ItemTag.id.in_(ids_to_add)).all())

        item.tags = new_tags  # replace existing tags
        new_qty = int(payload.get('quantity', 1))
        price = payload['price'] if payload['price'] else None

        item.name = payload['name']
        item.type = payload['type']
        item.trade_with = payload.get('trade_with', None)
        item.status = status
        item.price = price
        item.description = payload['description']
        item.reason = payload.get('reason', None)
        item.transaction_date = transaction_date

        # adjust original quantity
        if new_qty > item.quantity:
            additional_quantity = new_qty - item.quantity
            item.original_quantity += additional_quantity
        elif new_qty < item.quantity:
            additional_quantity = item.quantity - new_qty
            item.original_quantity -= additional_quantity

        item.quantity = new_qty

        updating_fields = ('updating item: %s', 'name: %s', 'type: %s',
            'status: %s', 'price: %s', 'quantity: %s', 'description: %s',
            'reason: %s', 'tags: %s', 'transaction date: %s\n')
        logger.info('\n'.join(updating_fields) % (item_id, item.name,
            item.type, item.status, item.price, item.quantity,
            item.description, item.reason, item.tags, item.transaction_date))

        DBSession.commit()
        return item.to_dict()

    @view(validators=('validate_item',))
    def delete(self):
        item_id = int(self.request.matchdict['item_id'])
        item = DBSession.query(Item).filter_by(id=item_id).one()
        logger.info("deleting item: %s" % item_id)
        item.is_deleted = True
        DBSession.add(item)
        DBSession.commit()
        return {'status': 'success', 'message': _(u'Item deletion successful')}

    ## validators

    def validate_posted_item(self, request):
        payload = MultiDict(request.json_body)

        # decimal can't convert None so we assign zero instead
        payload['price'] = payload['price'] if payload['price'] else 0

        item_form = ItemForm(payload)
        if not item_form.validate():
            for field, error in flatten_form_errors(item_form.errors).items():
                request.errors.add('body', field, error)

    def validate_status(self, request):
        status = request.GET.get('status', None)
        if status:
            try:
                DBSession.query(ItemStatus).filter_by(name=status.upper()).one()
            except NoResultFound:
                request.errors.add('url', 'status', _(u'Invalid status'))


@resource(
    collection_path='/%s/users/{user_id}/items/{item_id}/images' % API_VERSION,
    path='/%s/users/{user_id}/items/{item_id}/images/{image_id}' % API_VERSION,
    renderer='smartjson',
    validators=('validate_user', 'validate_item'))
class ItemImageService(BaseService):

    def collection_post(self):
        item_id = int(self.request.matchdict['item_id'])
        item = DBSession.query(Item).filter_by(id=item_id).one()
        ext = os.path.splitext(self.request.POST['image'].filename)[1] or '.jpg'
        filename_uuid = uuid.uuid4()
        filename = '%s%s' % (filename_uuid, ext)

        # figure out path to the newly uploaded image
        static_path = pkgr.resource_filename('tradeorsale', 'static')
        item_images_path = os.path.join('items/images', str(item_id))
        item_images_abspath = os.path.join(static_path, item_images_path)
        image_path = os.path.join(item_images_abspath, filename)

        # copy file chunk by chunk
        with open(image_path, 'wb') as handle:
            while True:
                data = self.request.POST['image'].file.read(2 << 16)  # 128kb
                if not data:
                    break
                handle.write(data)

        logger.info("storing item image to db: item-id(%i) size(original)" % item_id)
        item_image = ItemImage(item, filename,
            os.path.join('/%s' % item_images_path, filename))  # / + items/...

        # build resized images
        image_sizes = {}
        for size, dimension in THUMBNAIL_SIZES.items():
            resized_filename = '%s_%s%s' % (filename_uuid, size, ext)
            resized_image_path = os.path.join(item_images_abspath,
                                              resized_filename)

            # resize image
            logger.info("resizing image to %s" % str(THUMBNAIL_SIZES[size]))

            try:
                img = Image.open(image_path)
            except IOError as e:
                logger.error("unable to open image: %s" % str(e))
                self.request.errors.add('body', 'image', _(u'Unable to read image'))

            # if we're resizing to medium size, make height relative to width
            if size == 'medium':
                basewidth = THUMBNAIL_SIZES[size][0]
                width_percentage = (basewidth / float(img.size[0]))
                height_size = int((float(img.size[1]) * float(width_percentage)))
                resized_img = img.resize((basewidth, height_size),
                                         Image.ANTIALIAS)
            else:
                resized_img = ImageOps.fit(img, THUMBNAIL_SIZES[size],
                                           Image.ANTIALIAS)
            resized_img.save(resized_image_path, quality=90, optimize=True)

            # save resized image to db
            logger.info("storing item image to db: item-id(%i) size(%s)" % (
                item_id, size))
            item_subimage = ItemImage(item, resized_filename,
                os.path.join('/%s' % item_images_path, resized_filename), size)
            item_image.subimages.append(item_subimage)

        # save original image to db
        DBSession.add(item_image)
        DBSession.commit()

        # return different images sizes
        image_sizes = {'id': item_image.id,
                       'original': assets_url(self.request, item_image.path)}
        for size in THUMBNAIL_SIZES.keys():
            image_sizes[size] = assets_url(
                self.request, item_image.get_resized_image(size))

        return {'item_id': item_id, 'sizes': image_sizes}

    @view(validators=('validate_image',))
    def delete(self):
        image_id = int(self.request.matchdict['image_id'])
        item_image = DBSession.query(ItemImage).filter_by(id=image_id).one()
        DBSession.delete(item_image)
        DBSession.commit()
        return {'status': 'success', 'message': _(u'Image deletion successful')}

    ## validators

    def validate_image(self, request):
        try:
            item_id = int(request.matchdict['item_id'])
            image_id = int(request.matchdict['image_id'])
            try:
                DBSession.query(ItemImage).filter_by(
                    id=image_id, item_id=item_id).one()
            except NoResultFound:
                request.errors.add('url', 'image_id', _(u"Image doesn't exist"))
        except ValueError:
            request.errors.add('url', 'image_id', _(u'Invalid Image ID'))
