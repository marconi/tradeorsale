# -*- coding: utf-8 -*-

import os
import logging


PROJECT_ROOT = os.path.realpath(os.path.dirname(__file__))

INSTALLED_APPS = (
    'tradeorsale.apps.user',
    'tradeorsale.apps.item',
    'tradeorsale.apps.generic',
    'tradeorsale.apps.dashboard',
    'tradeorsale.apps.facebook'
)


def includeme(config):
    logger = logging.getLogger('tradeorsale')

    for app in INSTALLED_APPS:
        try:
            config.include('%s.urls' % app)
        except ImportError as e:
            logger.error("error loading app `%s`: %s" % (app, str(e)))
            pass
