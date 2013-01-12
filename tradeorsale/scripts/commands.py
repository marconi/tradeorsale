# -*- coding: utf-8 -*-

# import sys
# import optparse
# import textwrap
# from migrate.versioning.shell import main

# from pyramid.paster import bootstrap


# def tos_migrate():
#     description = "A wrapper to sqlalchemy-migrate's manage.py script."
#     parser = optparse.OptionParser(
#         usage="usage: %prog config_uri",
#         description=textwrap.dedent(description))

#     __, args = parser.parse_args(sys.argv[1:])
#     if len(args) == 0:
#         print "you need to pass config_uri"
#         return 2

#     config_uri = args[0]
#     sys.argv = args[1:] if len(args) > 1 else args

#     env = bootstrap(config_uri)
#     settings = env['registry'].settings

#     main(argv=sys.argv,
#          url=settings['sqlalchemy.url'],
#          debug='False',
#          repository='tradeorsale/migrations')
