# -*- coding: utf-8 -*-


def includeme(config):
    config.add_route('canvas', '/fb/')  # fb requires trailing slash
    config.add_route('channel', '/channel.html')
