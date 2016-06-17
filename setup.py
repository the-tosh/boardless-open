import os

from setuptools import setup, find_packages

here = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(here, 'README.txt')) as f:
		README = f.read()
with open(os.path.join(here, 'CHANGES.txt')) as f:
		CHANGES = f.read()

requires = [
		'pyramid==1.5',
		'pyramid_mako==1.0.2',
		'pyramid_debugtoolbar==2.0.2',
		'pyramid_tm==0.7',
		'pyramid-mailer==0.13',
		'SQLAlchemy==1.0.8',
		'transaction==1.4.1',
		'zope.sqlalchemy==0.7.4',
		'zope.deprecation==4.1.1',
		'zope.interface==4.1.1',
		'waitress==0.8.8',
		'argparse==1.2.1',
		'Mako==0.9.1',
		'MarkupSafe==0.23',
		'PasteDeploy==1.5.2',
		'repoze.lru==0.6',
		'repoze.sendmail==4.2',
		'translationstring==1.1',
		'venusian==1.0a8',
		'WebOb==1.3.1',
		'wsgiref==0.1.2',
		'Pygments==1.6',
		'psycopg2==2.5.2',
		'passlib==1.6.2',
		'wtforms==2.1.0',
		'setuptools==3.6',
		'watchdog==0.7.1',
		'PyYAML==3.11',
		'argh==0.24.1',
		'pathtools==0.1.2',
		'argcomplete==0.8',
		'bidict==0.3.1',
		'gevent==1.1a1',
		'greenlet==0.4.7',
		'gevent-websocket==0.9.5',
		'gunicorn==19.1.1',
		'psycogreen==1.0',
		'requests==2.9.1',
		'fabric==1.10',
		'paramiko==1.16.0',
		'pycrypto==2.6.1',
		'ecdsa==0.13',
	]

setup(name='boardless',
			version='0.1a',
			description='boardless',
			long_description=README + '\n\n' + CHANGES,
			classifiers=[
				"Programming Language :: Python",
				"Framework :: Pyramid",
				"Topic :: Internet :: WWW/HTTP",
				"Topic :: Internet :: WWW/HTTP :: WSGI :: Application",
			],
			author='',
			author_email='',
			url='',
			keywords='web wsgi bfg pylons pyramid',
			packages=find_packages(),
			include_package_data=True,
			zip_safe=False,
			test_suite='boardless',
			install_requires=requires,
			entry_points="""\
			[paste.app_factory]
			main = boardless:main
			[console_scripts]
			migrate = sapyens.migrate:run
			""",
	)
