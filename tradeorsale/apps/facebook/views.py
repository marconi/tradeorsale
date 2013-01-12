# -*- coding: utf-8 -*-

from pyramid.view import view_config


ONE_YEAR = 31536000  # no. of seconds in a year


@view_config(route_name='canvas', renderer='facebook/canvas.mako',
             permission='view')
def canvas(request):
    return {}


@view_config(route_name='channel', renderer='facebook/channel.mako',
             http_cache=(ONE_YEAR, {'public': True}), permission='view')
def channel(request):
    return {}
