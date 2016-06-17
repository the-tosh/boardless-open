# _*_ encoding: utf-8 _*_

import json
import inspect

from json import JSONEncoder
from decimal import Decimal

ROUTES = {}

# Note! State was moved here from main.py because of implicit behaviour (different State IDs in main.py and actions.py). This behaviour is caused by recursive imports.
class State (object):
	SETTINGS = {}

	clients_by_session = {}
	clients_by_character = {}
	clients_sockets = {}

	def __init__ (self):
		raise Exception("State class can not be instantiated")

	@classmethod
	def init_settings (cls, **kwargs):
		for option, value in kwargs.viewitems():
			cls.SETTINGS[option] = value

	@classmethod
	def add_client (cls, websocket, session_id, character_id):
		cls.clients_by_character[character_id] = (websocket, session_id)

		cls.clients_by_session.setdefault(session_id, {})
		cls.clients_by_session[session_id][character_id] = websocket

		cls.clients_sockets[websocket] = character_id

	@classmethod
	def forget_client (cls, websocket):
		if websocket in cls.clients_sockets: # If an user connected with invalid token
			character_id = cls.clients_sockets.pop(websocket)
			_, session_id = cls.clients_by_character.pop(character_id)

			cls.clients_by_session[session_id].pop(character_id)
			if not cls.clients_by_session[session_id]:
				cls.clients_by_session.pop(session_id)
			else:
				for client_id, client_websocket in cls.clients_by_session[session_id].viewitems():
					client_websocket.send(json.dumps({'call_action': 'CharacterDisconnected', 'params': {'character_id': character_id}}))

class CustomJSONEncoder (JSONEncoder):
	def default (self, val):
		if isinstance(val, Decimal):
			return str(val)
		return val

def add_route (name = None):
	def route_dec (act):
		global ROUTES

		ROUTES[name if name else act.__name__] = act
		return act
	return route_dec

def error_response (msg):
	return {'success': False, 'error': msg}

def handle_message (websocket, msg):
	try:
		msg = json.loads(msg)
	except ValueError:
		websocket.send(error_response('invalid message format'))
		return

	try:
		action_name = msg['action']
		params = msg['params']
	except KeyError:
		websocket.send(error_response('bad request'))
		return

	if action_name not in ROUTES:
		websocket.send(error_response('route does not exist'))
		return

	act = ROUTES[action_name]

	if inspect.isclass(act):
		response = act(websocket, params).check_and_process()
	else:
		response = act(websocket, params)

	if response is not None:
		websocket.send(json.dumps(response, cls = CustomJSONEncoder))