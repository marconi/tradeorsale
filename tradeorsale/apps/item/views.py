# -*- coding: utf-8 -*-

import logging
import simplejson as json
from socketio import socketio_manage
from socketio.namespace import BaseNamespace

from pyramid.view import view_config
from pyramid.response import Response

from tradeorsale.libs.utils import base36


logger = logging.getLogger('tradeorsale')
json_header = {'Content-Type': 'application/json'}


@view_config(route_name='item', request_method=['GET'],
             renderer='items/item.mako')
def items(request):
    item_id = base36.decode(request.matchdict['item_id'])
    return {'item_id': item_id}


class ItemsNamespace(BaseNamespace):
    def initialize(self):
        self.logger = logger
        self.logger.info("Socketio session started")

    def recv_connect(self):
        self.logger.info("connected")
        self.spawn(self.listener)

    def recv_disconnect(self):
        self.logger.info("disconnected")

    def listener(self):
        pubsub = self.redis.pubsub()
        pubsub.subscribe('user:1:items')
        for msg in pubsub.listen():
            if msg['type'] == 'message':
                data = json.loads(msg['data'])
                event_name = data.pop('event_name')
                self.logger.info('emitting %s: %s' % (event_name, data))
                self.emit(event_name, data)

    def on_comment_create(self, comment_info):
        """
        Handler for when a comment from facebook has been posted.
        """
        item_id = base36.decode(comment_info['item_id_b36'])
        if not self.redis.hget('comments:new:counter', item_id):
            self.redis.hset('comments:new:counter', item_id, 1)
        else:
            self.redis.hincrby('comments:new:counter', item_id)

        counter = int(self.redis.hget('comments:new:counter', item_id))
        self.redis.publish('user:1:items',
            json.dumps({'event_name': 'comments_counter',
                        'item_id': item_id,
                        'counter': counter}))

    def on_comments_counter_clear(self, item_id):
        """
        Handler for when user moves to comments tab
        thereby clearing the counter.
        """
        self.redis.hdel('comments:new:counter', item_id)
        self.redis.publish('user:1:items',
            json.dumps({'event_name': 'comments_counter',
                        'item_id': item_id,
                        'counter': 0}))

    @property
    def redis(self):
        return self.request.registry.redis


@view_config(route_name='socketio')
def socketio_service(request):
    socketio_manage(request.environ, {'/items': ItemsNamespace}, request)
    return Response()
