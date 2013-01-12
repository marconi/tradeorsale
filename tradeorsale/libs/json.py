# -*- coding: utf-8 -*-

import simplejson as json
from datetime import datetime


class JSONEncoder(json.JSONEncoder):
    """
    Simple JSON encoder that knows how to encode datetime objects.
    """
    def default(self, obj):
        if isinstance(obj, datetime):
            return obj.strftime("%m/%d/%Y %I:%M %p")
        else:
            return json.JSONEncoder.default(self, obj)


class JSONRenderer(object):
    """
    Pyramid renderer factory that uses custom JSONEncoder.
    """
    def __call__(self, data, context):
        response = context['request'].response
        response.content_type = 'application/json'
        return json.dumps(data, cls=JSONEncoder, use_decimal=True)


def json_renderer(helper):
    return JSONRenderer()
