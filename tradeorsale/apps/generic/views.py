# -*- coding: utf-8 -*-

import os
import pkg_resources as pkgr

from pyramid.view import view_config, forbidden_view_config
from pyramid.httpexceptions import HTTPUnauthorized
from pyramid.response import Response


@view_config(route_name='home', renderer='home.mako', permission='view')
def home(request):
    return {}


@forbidden_view_config()
def forbidden_view(request):
    """
    Forbidden view gets called when user is not authorized,
    here we just send a challenge to the user to authenticate itself.
    """
    resp = HTTPUnauthorized()
    resp.www_authenticate = 'Basic realm="Secure Area"'
    return resp


@view_config(route_name='favicon')
def favicon(request):
    static_path = pkgr.resource_filename('tradeorsale', 'static')
    with open(os.path.join(static_path, 'images', 'favicon.ico')) as handle:
        return Response(content_type='image/x-icon', body=handle.read())
