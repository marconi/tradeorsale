# # -*- coding: utf-8 -*-

# import logging
# from cornice import Service
# from sqlalchemy.orm.exc import NoResultFound

# from pyramid.i18n import TranslationString as _

# from tradeorsale.apps.item.models import Item
# from tradeorsale.libs.models import DBSession


# logger = logging.getLogger('tradeorsale')
# json_header = {'Content-Type': 'application/json'}
# event_service = Service(name='item_events', path='/items/events')

# VALID_ACTIONS = ('comment.created',)


# def validate_action(request):
#     action = request.POST.get('action', None)
#     if not action or action not in VALID_ACTIONS:
#         request.errors.add('body', 'action', _(u'Invalid action'))


# def validate_item(request):
#     try:
#         item_id = int(request.POST.get('item_id', 0))
#         try:
#             DBSession.query(Item).filter_by(id=item_id).one()
#         except NoResultFound:
#             request.errors.add('body', 'item_id', _(u"Item doesn't exist"))
#     except ValueError:
#         request.errors.add('body', 'item_id', _(u'Invalid Item ID'))


# @event_service.post(validators=(validate_action, validate_item))
# def item_event_post(request):
#     item_id = request.POST['item_id']
#     action = request.POST['action']
#     redis = request.registry.redis

#     if action == 'comment.created':
#         if not redis.hget('comments:counter', item_id):
#             redis.hset('comments:counter', item_id, 1)
#         else:
#             redis.hincrby('comments:counter', item_id)
#     return True
