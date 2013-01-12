# -*- coding: utf-8 -*-

from pyramid.security import Allow, Everyone


class RootFactory(object):

    __acl__ = [(Allow, 'group:developers', 'view'),
               (Allow, 'group:developers', 'edit')]

    def __init__(self, request):

        # when on debug mode, allow all permissions
        if bool(request.registry.settings.get('tradeorsale.debug', False)):
            for i, entry in enumerate(self.__acl__):
                self.__acl__[i] = (entry[0], Everyone, entry[2])

        self.request = request
