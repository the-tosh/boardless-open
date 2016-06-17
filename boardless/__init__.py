import decimal

import sapyens.helpers

import pyramid
import pyramid.authentication
import pyramid.authorization

from pyramid.config import Configurator
from pyramid.renderers import JSON

from sqlalchemy import engine_from_config

import boardless.db
import boardless.views

from boardless import helpers as h
from boardless.db import models, DBSession

def main (global_config, **settings):
	""" This function returns a Pyramid WSGI application.
	"""
	sapyens.helpers.set_utc_timezone()

	engine = engine_from_config(settings, 'sqlalchemy.')
	boardless.db.init(engine, settings)

	config = Configurator(
			settings = settings,
			root_factory = RootFactory,
			session_factory = pyramid.session.SignedCookieSessionFactory(
				# The secret should be at least as long as the block size of the selected hash algorithm. For sha512 this would mean a 128 bit (64 character) secret.
				# For sha512 this would mean a 128 bit (64 character) secret
				secret = 'sETbVPAqkZxJTneqWpgnczyGhuwtfHNYMFZUMVwRjDiIRuSKGzdymHNBjDatQlhr',
				hashalg = 'sha512',
				cookie_name = 'boardless.session',
				timeout = 60 * 60 * 24 * 3, # A number of seconds of inactivity before a session times out. If None then the cookie never expires
				max_age = 60 * 60 * 24 * 3, # The maximum age of the cookie used for sessioning (in seconds). Default: None (browser scope).
				domain = settings.get('cookie_domain', '.boardless.com'), # TODO
				set_on_exception = True, # If True, set a session cookie even if an exception occurs while rendering a view
			),
			authentication_policy = pyramid.authentication.SessionAuthenticationPolicy(
				callback = get_identifiers,
				debug = False
			),
			authorization_policy = pyramid.authorization.ACLAuthorizationPolicy(),
	)

	# Mailer
	config.include('pyramid_mailer')

	json_renderer = JSON()
	json_renderer.add_adapter(decimal.Decimal, h.decimal_json_encoder)

	config.add_renderer('json', json_renderer)
	config.set_request_property(h.get_user, 'user')
	config.add_static_view('static', 'static', cache_max_age = 3600)
	config.scan(boardless.views)

	# Recreate the pool to close left connections (e.g. after reflection)
	# It prevents connection sharing between later-forked server workers (e.g. gunicorn with preload_app)
	DBSession.remove()
	engine.dispose()

	return config.make_wsgi_app()

class RootFactory (object):
	__acl__ = [
		(pyramid.security.Allow, 'group:admin', pyramid.security.ALL_PERMISSIONS),
		(pyramid.security.Allow, 'group:unconfirmed', 'view'),
		(pyramid.security.Allow, 'group:confirmed', 'view'),
	]

	def __init__ (self, request):
		pass

def get_identifiers (userid, request):
	user = models.User.query.filter(models.User.email == userid).first()
	if not user:
		return []

	return ['group:{0}'.format(user.group)]
