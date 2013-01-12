# -*- coding: utf-8 -*-

import os
import logging
import pkg_resources as pkgr
from datetime import date, datetime, timedelta

from pyramid.httpexceptions import HTTPForbidden


_os_alt_seps = list(sep for sep in [os.path.sep, os.path.altsep]
                    if sep not in (None, '/'))


logger = logging.getLogger('tradeorsale')


def assets_url(request, path):
    """
    Return a versioned URL for an asset.

    The versioning scheme consists in basing the version number upon the file's
    last modified time and appending it to the given path as a query string.
    """
    asset_path = pkgr.resource_filename('tradeorsale', 'static%s' % path)
    url = ''
    try:
        modified = int(os.stat(asset_path).st_mtime)
        url = "%s?v=%d" % (request.static_url('tradeorsale:static%s' % path),
                           modified)
    except OSError as e:
        logger.error("error in asset url: %s" % str(e))
    return url


def copyright_year(base_year=2012):
    """
    Return a copyright year that works for ever.
    """
    cur_year = date.today().year
    return str(base_year) + ('-%d' % cur_year if cur_year > base_year else '')


def get_settings(request, key, default=''):
    """
    Helper function to access settings directly from templates.
    """
    setting = request.registry.settings.get(key, default)
    if setting and key == 'meta_expires':
        duration_unit = {'h': 'hours', 'd': 'days', 'w': 'weeks'}
        duration = duration_unit.get(setting[-1], None)
        if not duration:
            raise Exception("Unknown meta_expires settings '%s'" % setting)
        d = datetime.now() + timedelta(**{duration: int(setting[:-1])})
        setting = d.strftime("%a, %d %b %Y %H:%M:%S GMT")
    return setting


def flatten_form_errors(errors):
    """
    Return a flat version of form errors so errors like:
        {description: ["This field is required."]}

    will become:
        {description: "This field is required."}
    """
    for k, v in errors.items():
        if len(v) == 1:
            errors[k] = v[0]
    return errors


def csrf_check(context, request):
    """
    Checks for csrf validation explicitly from POSTed data.
    """
    if request.method == "POST":
        token = request.POST.get("_csrf", None)
        # if we don't have it in normal POST, and this is ajax,
        # check in json encoded body.
        if not token and request.is_xhr:
            token = request.json_body.get("_csrf", None)
        if not token or token != request.session.get_csrf_token():
            raise HTTPForbidden("CSRF token is missing or invalid")
