# -*- coding: utf-8 -*-

from redis import StrictRedis
from sqlalchemy import engine_from_config
from paste.deploy.converters import asbool

from pyramid.config import Configurator
from pyramid_beaker import session_factory_from_settings
from pyramid.authorization import ACLAuthorizationPolicy

from tradeorsale.libs.models import initialize_db
from tradeorsale.libs.json import json_renderer
from tradeorsale.resources import RootFactory
from tradeorsale.libs.auth import BasicAuthenticationPolicy, auth_check


def main(global_config, **settings):
    """
    This function returns a Pyramid WSGI application.
    """

    # cast settings to proper boolean
    settings['tradeorsale.debug'] = asbool(settings.get('tradeorsale.debug', False))

    # init authentication
    authn_policy = BasicAuthenticationPolicy(auth_check)
    authz_policy = ACLAuthorizationPolicy()

    config = Configurator(settings=settings,
                          root_factory=RootFactory,
                          authentication_policy=authn_policy,
                          authorization_policy=authz_policy)

    # load extensions
    config.include('pyramid_beaker')
    config.include('cornice')

    # load renderers
    config.add_renderer('smartjson', json_renderer)

    # init session
    config.set_session_factory(session_factory_from_settings(settings))

    config.scan(ignore=['tradeorsale.migrations',
                        'tradeorsale.tests'])  # start scanning packages
    config.add_static_view('static', 'tradeorsale:static')  # , cache_max_age=3600

    # load models and initialize db
    engine = engine_from_config(settings, 'sqlalchemy.')
    initialize_db(engine)

    # load redis
    redis = StrictRedis(host=settings['redis.host'],
                        port=int(settings['redis.port']),
                        db=int(settings['redis.db']))
    config.registry.redis = redis

    # load apps' settings
    config.include('tradeorsale.settings')

    return config.make_wsgi_app()
