# _*_ coding: utf-8 _*_

# Sorry, PEP, but I need it here
import psycogreen.gevent
import gevent
import gevent.monkey

gevent.monkey.patch_all()
psycogreen.gevent.patch_psycopg()

from geventwebsocket.websocket import WebSocketError
from geventwebsocket.handler import WebSocketHandler
# Do not touch order of imports above!

import logging
import argparse
from ConfigParser import ConfigParser

import sqlalchemy

from pyramid.paster import setup_logging

from boardless import db
from boardless.db import DBSession
from boardless.server import utils
from boardless.server.utils import State
import boardless.server.actions # Must be here to process decorators

logger = logging.getLogger('boardless')

class QuietWebSocketHandler (WebSocketHandler):
	def log_request (self, *args, **kwargs):
		pass # 'dont spam to stderr'

def websocket_app (environ, start_response):
	try:
		if environ['PATH_INFO'] == '/playground':
			websocket = environ['wsgi.websocket']

			while True:
				try:
					data = websocket.receive()
					if not data:
						State.forget_client(websocket)
						break
					else:
						utils.handle_message(websocket, data)

				except WebSocketError:
					raise

				finally:
					DBSession.remove()


	except Exception:
		logger.warn("Playfield: uncaught error is occured.", exc_info = True)
		# environ['server'].stop()
		# raise

def run (settings):
	host = '0.0.0.0' # settings.get('connection', 'host')
	port = settings.getint('connection', 'port')

	State.init_settings(web_url = settings.get('main', 'web_url'))

	db.init(sqlalchemy.engine_from_config({
		'sqlalchemy.url': settings.get('database', 'url'),
	}), {})

	logger.info("listening on ws://%s:%s", host, port)
	websocket_server = gevent.pywsgi.WSGIServer((host, port), websocket_app, handler_class = QuietWebSocketHandler)
	websocket_server.set_environ({
		'server': websocket_server,
	})
	websocket_server.start()

	try:
		websocket_server.serve_forever()
	except KeyboardInterrupt:
		logger.info("interrupted")
	else:
		logger.info("[!] stopped due to error")

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description = 'Runs the epic playground server')
	parser.add_argument('config', type = str, help = "configuration file")
	args = parser.parse_args()

	settings = ConfigParser()
	settings.readfp(open(args.config, 'r'))

	setup_logging(args.config)

	if settings.has_section('main') and settings.has_option('main', 'is_dev') and settings.getboolean('main', 'is_dev'):
		from boardless.scripts.compile_static import create_client_settings
		create_client_settings(settings)

	run(settings)