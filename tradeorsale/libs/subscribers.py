# -*- coding: utf-8 -*-

import simplejson as json

from pyramid.events import BeforeRender, NewRequest, subscriber
from pyramid.i18n import get_localizer, TranslationStringFactory
from pyramid.threadlocal import get_current_request
from pyramid.exceptions import ConfigurationError

from tradeorsale.libs import helpers
from tradeorsale.libs.models import DBSession
from tradeorsale.apps.item.models import ItemTag
from tradeorsale.apps.item.forms import ItemForm


tsf = TranslationStringFactory('tradeorsale')


@subscriber(BeforeRender)
def add_renderer_globals(event):
    request = event.get('request')
    if request is None:
        request = get_current_request()

    globs = {'h': helpers}

    if request is not None:
        globs['_'] = request.translate
        globs['localizer'] = request.localizer
        try:
            globs['session'] = request.session
        except ConfigurationError:
            pass

    def url(*args, **kwargs):
        """ route_url shorthand """
        return request.route_url(*args, **kwargs)

    tag_names = [tag.to_dict() for tag in DBSession.query(ItemTag).all()]

    globs['url'] = url
    globs['tag_names'] = json.dumps(tag_names)
    globs['post_item_form'] = ItemForm()

    event.update(globs)


@subscriber(NewRequest)
def add_localizer(event):
    request = event.request
    localizer = get_localizer(request)

    def auto_translate(string, **kwargs):
        return localizer.translate(tsf(string, **kwargs))

    request.localizer = localizer
    request.translate = auto_translate


# @subscriber(NewRequest)
# def csrf_validation(event):
#     if event.request.method == "POST":
#         token = event.request.POST.get("_csrf", None)
#         # if we don't have it in normal POST, and this is ajax,
#         # check in json encoded body.
#         if not token and event.request.is_xhr:
#             token = event.request.json_body.get("_csrf", None)
#         if not token or token != event.request.session.get_csrf_token():
#             raise HTTPForbidden("CSRF token is missing or invalid")


# @subscriber(NewResponse)
# def pass_new_csrf_on_post(event):
#     request = event.request
#     response = event.response
#     if request.method == "POST" and request.is_xhr:
#         # if we can try, convert the response to dict,
#         # add the new csrf token to the response.
#         try:
#             response_body = json.loads(response.body)
#             if isinstance(response_body, dict):
#                 print "generating new csrf..."
#                 response_body['new_csrf'] = request.session.new_csrf_token()
#                 response.body = json.dumps(response_body)
#         except ValueError:
#             pass
