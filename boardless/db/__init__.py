import os

# from pyramid.settings import asbool

import sapyens.db


DBSession, QueryPropertyMixin, ScopedSessionMixin = sapyens.db.make_classes(use_zope_ext = not bool(os.environ.get('nozope')))

class Model (sapyens.db.Reflected, QueryPropertyMixin, ScopedSessionMixin):
	__abstract__ = True

def init (engine, settings):
	sapyens.db.init(engine, DBSession, Model, settings,
		import_before_reflect = 'boardless.db.models',
		# enable_setattr_check = asbool(settings.get('sapyens.db.enable_setattr_check', False))
	)
