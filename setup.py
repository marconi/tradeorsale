# -*- coding: utf-8 -*-

import os
from setuptools import setup, find_packages


here = os.path.abspath(os.path.dirname(__file__))
README = open(os.path.join(here, 'README.rst')).read()
CHANGES = open(os.path.join(here, 'CHANGES.txt')).read()

requires = [
    'pyramid==1.3.2',
    'Paste==1.7.5.1',
    'pyramid_debugtoolbar==1.0.2',
    'Mako==0.7.3',
    'waitress==0.8.1',
    'WTForms==1.0.1',
    'pyramid_beaker==0.6.1',
    'SQLAlchemy==0.7.9',
    'alembic==0.4.0',
    'simplejson==2.5.2',
    'psycopg2==2.4.5',
    'redis==2.7.2',
    'redish==0.0.1',
    'beaker-extensions==0.2.0dev',
    'Pillow==1.7.8',
    'nose==1.2.1',
    'coverage==3.5.3',
    'cornice==0.12',
    'pyScss==1.1.4'
]

setup(name='tradeorsale',
      version='0.1',
      description='Trading or Selling platform.',
      long_description=README + '\n\n' + CHANGES,
      classifiers=[
        "Programming Language :: Python",
        "Framework :: Pylons",
        "Topic :: Internet :: WWW/HTTP",
        "Topic :: Internet :: WWW/HTTP :: WSGI :: Application",
        ],
      author='Marconi Moreto',
      author_email='caketoad@gmail.com',
      url='',
      keywords='web pyramid pylons',
      packages=find_packages(),
      include_package_data=True,
      zip_safe=False,
      install_requires=requires,
      dependency_links=[
        'https://github.com/didip/beaker_extensions/tarball/master#egg=beaker_extensions-0.2.0dev'
      ],
      tests_require=requires,
      test_suite="tradeorsale",
      entry_points="""\
      [paste.app_factory]
      main = tradeorsale:main
      """
)

      # [console_scripts]
      # tos_migrate = tradeorsale.scripts.commands:tos_migrate
