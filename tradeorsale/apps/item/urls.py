# -*- coding: utf-8 -*-


def includeme(config):
    config.add_route('items', '/items')
    config.add_route('item', '/items/{item_id}')

    # socketio
    config.add_route('socketio', '/socket.io/*remaining')
