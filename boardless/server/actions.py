# _*_ encoding: utf-8 _*_

import copy
import json

from string import strip

from wtforms import fields
from wtforms import validators as v
from wtforms.form import Form
from wtforms.ext.sqlalchemy.fields import QuerySelectField

from webob.multidict import MultiDict

from sqlalchemy import INTEGER
from sqlalchemy.orm.attributes import flag_modified

from boardless import constants
from boardless.forms import FieldForm, ParentForm, STRING_OUTPUT_FILTERS, INT4_MAX_VALUE
from boardless.db import models, DBSession
from boardless.server.utils import add_route, error_response, State, CustomJSONEncoder

# TODO: split the actions to several files in a module?
class ParentAction (Form):
	request_id = fields.IntegerField(validators = [v.Optional()])

	def __init__ (self, websocket, params):
		self.websocket = websocket
		self.params = params
		super(ParentAction, self).__init__(MultiDict(params))

	# TODO: Move to the State?
	def call_client_action (self, character_id, action_name, params):
		data = json.dumps({'call_action': action_name, 'params': params}, cls = CustomJSONEncoder)
		websocket, _ = State.clients_by_character[character_id] # TODO: Validate if receiver is in the same session with sender
		websocket.send(data)

	def group_call_client_action (self, action_name, params, include_sender = False):
		data = json.dumps({'call_action': action_name, 'params': params}, cls = CustomJSONEncoder)

		character_id = State.clients_sockets[self.websocket]
		_, session_id = State.clients_by_character[character_id]

		for _, websocket in State.clients_by_session[session_id].viewitems():
			if include_sender or (websocket is not self.websocket):
				websocket.send(data)

	def handle (self):
		return self.params

	def check_and_process (self):
		if self.websocket not in State.clients_sockets:
			response = error_response('Forbidden')
			if self.request_id.data:
				response['request_id'] = self.request_id.data
			return response

		if not self.validate():
			response = error_response('Validation error')
			if self.request_id.data:
				response['request_id'] = self.request_id.data
			return response

		response = self.handle()
		if self.request_id.data:
			response['request_id'] = self.request_id.data

		return response

class MulticaseParentAction (object):
	def __init__ (self, websocket, params):
		self.websocket = websocket
		self.params = MultiDict(params)

	def handle (self):
		return self.params

	def check_and_process (self):
		if self.websocket not in State.clients_sockets:
			response = error_response('Forbidden')
			response['request_id'] = self.params.get('request_id')
			return response

		response = self.handle()
		if 'request_id' in self.params:
			response['request_id'] = self.params['request_id']

		return response

	# TODO: Move to the State?
	def call_client_action (self, character_id, action_name, params):
		data = json.dumps({'call_action': action_name, 'params': params}, cls = CustomJSONEncoder)
		websocket, _ = State.clients_by_character[character_id] # TODO: Validate if receiver is in the same session with sender
		websocket.send(data)

	def group_call_client_action (self, action_name, params, include_sender = False):
		data = json.dumps({'call_action': action_name, 'params': params}, cls = CustomJSONEncoder)

		character_id = State.clients_sockets[self.websocket]
		_, session_id = State.clients_by_character[character_id]

		for _, websocket in State.clients_by_session[session_id].viewitems():
			if include_sender or (websocket is not self.websocket):
				websocket.send(data)

@add_route()
class Authenticate (ParentAction):
	token = fields.StringField(default = "", filters = [strip], validators = [v.DataRequired()])

	def handle (self):
		token = self.token.data

		character = models.SessionCharacter.query.filter_by(token = token).first()
		if not character:
			return error_response('Invalid token')

		State.add_client(self.websocket, character.game_session_id, character.id)

		self.group_call_client_action("CharacterJoined", {'character': character.as_dict()}, include_sender = False)

		return {'success': True, 'is_authorized': True}

	def check_and_process (self):
		if not self.validate():
			return error_response('Validation error')

		return self.handle()

#############################################################
# Game session actions
#############################################################
@add_route()
class LoadPlayfield (ParentAction):
	game_session_id = fields.IntegerField(validators = [v.DataRequired()])
	request_id = fields.IntegerField(validators = [v.DataRequired()])

	def handle (self):
		game_session = models.GameSession.query.get(self.game_session_id.data)
		if not game_session:
			return error_response('Invalid session ID')

		static_path = '{0}/static/'.format(State.SETTINGS.get('web_url'))
		playfield_objects = [x.as_dict(static_path) for x in models.PlayObject.query.filter_by(game_session_id = game_session.id, is_deleted = False)]

		return {
			'success': True,
			'image': game_session.board_image,
			'playfield_objects': playfield_objects,
			'request_id': self.request_id.data,
		}

@add_route()
class SaveImage (ParentAction):
	game_session_id = fields.IntegerField(validators = [v.DataRequired()])
	image = fields.StringField(filters = [str], validators = [v.DataRequired()])

	def handle (self):
		game_session = models.GameSession.query.get(self.game_session_id.data)
		if not game_session:
			return error_response('Invalid session ID')

		character_id = State.clients_sockets[self.websocket]
		is_master = models.SessionCharacter.query.filter_by(
			id = character_id,
			game_session_id = self.game_session_id.data,
			user_role = "master",
		).count()
		if not is_master:
			return error_response('Forbidden')

		game_session.board_image = self.image.data
		game_session.add()

		DBSession.commit()

		self.group_call_client_action('ReloadPlayfield', {})

		return {'success': True}

@add_route()
class UpdatePlayfieldTokenPoint (ParentAction):
	game_session_id = fields.IntegerField(validators = [v.DataRequired()])
	object_id = fields.IntegerField(validators = [v.DataRequired()])
	x = fields.FloatField(validators = [v.DataRequired()])
	y = fields.FloatField(validators = [v.DataRequired()])

	def handle (self):
		character_id = State.clients_sockets[self.websocket]

		is_master = models.SessionCharacter.query.filter_by(
			id = character_id,
			game_session_id = self.game_session_id.data,
			user_role = "master",
		).count()
		if not is_master:
			return error_response('Forbidden')

		obj = models.PlayObject.query.get(self.object_id.data)
		if not obj:
			return error_response('Invalid token')

		obj.x = self.x.data
		obj.y = self.y.data
		obj.add()

		DBSession.commit() # TODO: wrapper?

		obj.add()
		data = {'obj_id': obj.id, 'obj_type': constants.PlayfieldObject.NAME_TO_TYPE.inv[obj.type], 'x': obj.x, 'y': obj.y}
		self.group_call_client_action('MovePlayfieldObject', data)

		return {'success': True}

@add_route()
class CharacterSaveSkills (ParentAction):
	class _SkillToApply (FieldForm):
		id = fields.IntegerField(validators = [v.DataRequired()])
		value = fields.IntegerField(validators = [v.InputRequired()])

	game_session_id = fields.IntegerField(validators = [v.DataRequired()])
	skills = fields.FieldList(fields.FormField(_SkillToApply), min_entries = 1)

	def handle (self):
		character_id = State.clients_sockets[self.websocket]

		game_session_id = self.game_session_id.data
		character = models.SessionCharacter.query.filter_by(id = character_id, game_session_id = game_session_id).first()
		if not character or character.user_role != "player":
			return error_response('Forbidden')

		new_skills_dict = {skill['id']: skill['value'] for skill in self.skills.data}
		skills = DBSession.query(models.Skill.id, models.Skill.category_id, models.Skill.formula).filter(models.Skill.id.in_(character.skills.keys())).all()
		skills_categories_mapper = {skill.id: skill.category_id for skill in skills}
		skills_with_formulas = {skill.id: True for skill in skills if skill.formula}

		char_skills = copy.copy(character.skills)
		char_skill_points = copy.copy(character.skill_points)

		for skill_id, val_to_add in new_skills_dict.viewitems():
			if val_to_add <= 0:
				continue # TODO: error?

			if skill_id in skills_with_formulas:
				continue

			skill_id = int(skill_id)

			category_id = skills_categories_mapper[skill_id]
			cat_points = char_skill_points[str(category_id)]

			if cat_points < val_to_add:
				continue # TODO: error?

			char_skills[str(skill_id)] += val_to_add
			char_skill_points[str(category_id)] -= val_to_add

		character.skills = char_skills
		character.skill_points = char_skill_points
		character.add()

		DBSession.commit()

		character.add()
		skills = character.get_skills()
		data = {'character_id': character_id, 'skills': skills, 'skill_points': character.skill_points}
		self.group_call_client_action("AfterCharacterChangeSkills", data, include_sender = True)

		return {'success': True, 'skills': skills}

@add_route()
class CharacterPutItemOn (ParentAction):
	item_id = fields.IntegerField(validators = [v.DataRequired()])
	game_session_id = fields.IntegerField(validators = [v.DataRequired()])

	def handle (self):
		character_id = State.clients_sockets[self.websocket]

		game_session_id = self.game_session_id.data
		character = models.SessionCharacter.query.filter_by(id = character_id, game_session_id = game_session_id).first()
		if not character or character.user_role != "player":
			return error_response('Forbidden')

		item_id = self.item_id.data
		session_item = models.SessionItem.query.filter_by(id = item_id, owner_id = character.id).first()

		if session_item:
			item = session_item.item
			if not item:
				return error_response('Item not found')

			item_group = item.item_group
			if not item_group.is_equippable:
				return error_response('Item is not wearable')

			group_items = models.Item.query.filter(models.Item.group_id == item_group.id)
			items_by_ids = {}
			for group_item in group_items:
				items_by_ids[group_item.id] = group_item

			slots_consumed = 0
			for character_item in character.items_query:
				if character_item.attrs.get('is_equipped') == True and character_item.item_id in items_by_ids:
					it = items_by_ids[character_item.item_id]
					slots_consumed += it.attrs['slots_consumed']

			if slots_consumed + item.attrs['slots_consumed'] > item_group.max_worn_items:
				return {'success': False}

			session_item.attrs['is_equipped'] = True
			session_item.attrs = session_item.attrs
			flag_modified(session_item, 'attrs')
			session_item.add()

		DBSession.commit()

		character.add()
		items = character.get_items()
		data = {'character_id': character.id, 'items': items, 'skills': character.get_skills()}
		self.group_call_client_action("AfterCharacterPutItemOn", data, include_sender = True)

		return {'success': True, 'items': items}

@add_route()
class CharacterTakeItemOff (ParentAction):
	item_id = fields.IntegerField(validators = [v.DataRequired()])
	game_session_id = fields.IntegerField(validators = [v.DataRequired()])

	def handle (self):
		character_id = State.clients_sockets[self.websocket]

		game_session_id = self.game_session_id.data
		character = models.SessionCharacter.query.filter_by(id = character_id, game_session_id = game_session_id).first()
		if not character or character.user_role != "player":
			return error_response('Forbidden')

		item_id = self.item_id.data
		session_item = models.SessionItem.query.filter_by(id = item_id, owner_id = character.id).first()
		if session_item:
			session_item.attrs['is_equipped'] = False
			flag_modified(session_item, 'attrs')
			session_item.add()

			DBSession.commit()

		character.add()
		items = character.get_items()
		data = {'character_id': character.id, 'items': items, 'skills': character.get_skills()}
		self.group_call_client_action("AfterCharacterTookItemOff", data, include_sender = True)

		return {'success': True, 'items': items}

# @add_route()
class CharacterChangeCategoryPoints (ParentAction):
	class _PointToApply (FieldForm):
		character_id = fields.IntegerField(validators = [v.DataRequired()])
		category_id = fields.IntegerField(validators = [v.DataRequired()])
		value = fields.IntegerField(validators = [v.InputRequired()])

	game_session_id = fields.IntegerField(validators = [v.DataRequired()])
	points = fields.FieldList(fields.FormField(_PointToApply), min_entries = 1)

	def handle (self):
		character_id = State.clients_sockets[self.websocket]
		is_master = models.SessionCharacter.query.filter_by(
			id = character_id,
			game_session_id = self.game_session_id.data,
			user_role = "master",
		).count()
		if not is_master:
			return error_response('Forbidden')

		character_ids = [points_data['character_id'] for points_data in self.points.data]
		characters = models.SessionCharacter.query.filter(models.SessionCharacter.id.in_(character_ids))
		character_by_ids = {}
		for character in characters:
			character_by_ids[character.id] = character

		data_to_send = []
		for points_data in self.points.data:
			character_id = points_data['character_id']
			category_id = points_data['category_id']
			value = points_data['value']

			character = character_by_ids[character_id]
			character_points = copy.copy(character.skill_points)
			character_points[str(category_id)] += value
			character.skill_points = character_points
			character.add()

			data_to_send.append((character_id, category_id, character_points[str(category_id)]))

		DBSession.commit()

		self.group_call_client_action("MasterChangedCategoryPoints", {'data_tpls': data_to_send})

		return {'success': True}

@add_route()
class PlayfieldTokenCreate (MulticaseParentAction):
	class CheckType (ParentForm):
		object_type = fields.SelectField(choices = constants.PlayfieldObject.TO_SELECT, validators = [v.DataRequired()], coerce = str)

	class GeneralCase (CheckType):
		game_session_id = fields.IntegerField(validators = [v.DataRequired()])
		tmp_key = fields.StringField(validators = [v.DataRequired()])
		x = fields.FloatField(validators = [v.DataRequired()])
		y = fields.FloatField(validators = [v.DataRequired()])

	class NPCCase (GeneralCase):
		title = fields.StringField(default = "", filters = STRING_OUTPUT_FILTERS, validators = [v.DataRequired()])

	class PlayerCase (GeneralCase):
		player_id = fields.IntegerField(validators = [v.DataRequired()]) # TODO: DBExists validator

	class ItemCase (GeneralCase):
		item = QuerySelectField(allow_blank = False, get_label = lambda x: x.title)
		durability = fields.IntegerField(default = 1, validators = [v.DataRequired(), v.NumberRange(min = 1, max = INT4_MAX_VALUE)])

	def handle (self):
		player_id = None

		object_forms_by_type = {
			constants.PlayfieldObject.STR_NPC: self.NPCCase,
			constants.PlayfieldObject.STR_ITEM: self.ItemCase,
			constants.PlayfieldObject.STR_PLAYER: self.PlayerCase,
		}

		check_form = self.CheckType(self.params)
		if not check_form.validate():
			resp = check_form.errors
			resp['tmp_key'] = self.params.get('tmp_key')
			return resp

		form = object_forms_by_type[check_form.object_type.data](self.params)

		if check_form.object_type.data == constants.PlayfieldObject.STR_ITEM:
			game_session = models.GameSession.query.filter_by(id = form.game_session_id.data).first()
			form.item.query = models.Item.query.filter_by(rules_id = game_session.rules_id)

		if not form.validate():
			resp = form.errors
			resp['tmp_key'] = self.params.get('tmp_key')
			return resp

		if check_form.object_type.data == constants.PlayfieldObject.STR_PLAYER:
			player_id = form.player_id.data

			player_tokens = models.PlayObject.query.filter(
				models.PlayObject.game_session_id == form.game_session_id.data,
				models.PlayObject.attrs['player_id'].cast(INTEGER) == form.player_id.data,
				models.PlayObject.is_deleted == False,
			)
			if player_tokens.count():
				return error_response('Player is already on the field')

		character_id = State.clients_sockets[self.websocket]
		is_master = models.SessionCharacter.query.filter_by(
			id = character_id,
			game_session_id = form.game_session_id.data,
			user_role = "master",
		).count()
		if not is_master:
			return error_response('Forbidden')

		tmp_key = form.data.pop('tmp_key')
		type_name = form.data.pop('object_type')

		obj = models.PlayObject()
		form.populate_obj(obj)
		obj.type = constants.PlayfieldObject.NAME_TO_TYPE[type_name]
		obj.is_deleted = False

		if obj.type == constants.PlayfieldObject.PLAYER:
			obj.attrs = {'player_id': form.player_id.data}
		elif obj.type == constants.PlayfieldObject.ITEM:
			session_item = models.SessionItem(
				rules_id = game_session.rules_id,
				item_id = form.item.data.id,
				attrs = {'durability': form.durability.data}
			).add()
			session_item.flush()

			obj.title = form.item.data.title
			obj.attrs = {'item': session_item.id}

		obj.add()

		DBSession.commit()

		self.group_call_client_action('ReloadPlayfield', {})

		DBSession.add(obj)

		return {'success': True, 'object_id': obj.id, 'tmp_key': tmp_key, 'player_id': player_id}

@add_route()
class UpdatePlayfieldToken (MulticaseParentAction):
	class CheckType (ParentForm):
		object_type = fields.SelectField(choices = constants.PlayfieldObject.TO_SELECT, validators = [v.DataRequired()], coerce = str)

	class GeneralCase (CheckType):
		id = fields.IntegerField(validators = [v.DataRequired()])
		game_session_id = fields.IntegerField(validators = [v.DataRequired()])

	class NPCCase (GeneralCase):
		title = fields.StringField(default = "", filters = STRING_OUTPUT_FILTERS, validators = [v.DataRequired()])

	class ItemCase (GeneralCase):
		item = QuerySelectField(allow_blank = False, get_label = lambda x: x.title)
		durability = fields.IntegerField(default = 1, validators = [v.DataRequired(), v.NumberRange(min = 1, max = INT4_MAX_VALUE)])

	def handle (self):
		object_forms_by_type = {
			constants.PlayfieldObject.STR_NPC: self.NPCCase,
			constants.PlayfieldObject.STR_ITEM: self.ItemCase,
		}

		check_form = self.CheckType(self.params)
		if not check_form.validate():
			return check_form.errors

		form = object_forms_by_type[check_form.object_type.data](self.params)

		if check_form.object_type.data == constants.PlayfieldObject.STR_ITEM:
			game_session = models.GameSession.query.filter_by(id = form.game_session_id.data).first()
			form.item.query = models.Item.query.filter_by(rules_id = game_session.rules_id)

		if not form.validate():
			return form.errors

		character_id = State.clients_sockets[self.websocket]
		is_master = models.SessionCharacter.query.filter_by(
			id = character_id,
			game_session_id = form.game_session_id.data,
			user_role = "master",
		).count()
		if not is_master:
			return error_response('Forbidden')

		obj = models.PlayObject.query.filter_by(id = form.id.data).first()
		if not obj:
			return error_response('Object is not found')

		if obj.type == constants.PlayfieldObject.ITEM:
			obj.attrs = {'item': form.item.data.id}
			obj.title = form.item.data.title

		elif obj.type == constants.PlayfieldObject.NPC:
			obj.title = form.title.data

		obj.add()

		DBSession.commit()

		self.group_call_client_action('ReloadPlayfield', {})

		return {'success': True}

@add_route()
class PlayfieldTokenDelete (ParentAction):
	id = fields.IntegerField(validators = [v.DataRequired()])
	game_session_id = fields.IntegerField(validators = [v.DataRequired()])

	def handle (self):
		character_id = State.clients_sockets[self.websocket]
		is_master = models.SessionCharacter.query.filter_by(
			id = character_id,
			game_session_id = self.game_session_id.data,
			user_role = "master",
		).count()
		if not is_master:
			return error_response('Forbidden')

		obj = models.PlayObject.query.filter_by(game_session_id = self.game_session_id.data, id = self.id.data).first()
		if not obj:
			return error_response('Object is not found')

		obj.is_deleted = True
		obj.add()

		DBSession.commit()

		obj.add()
		data = {'obj_id': obj.id, 'obj_type': constants.PlayfieldObject.NAME_TO_TYPE.inv[obj.type]}
		self.group_call_client_action('DeletePlayfieldObject', data)

		return {'success': True}

@add_route()
class CharacterPickUpPlayfieldObject (ParentAction):
	obj_id = fields.IntegerField(validators = [v.DataRequired()])
	game_session_id = fields.IntegerField(validators = [v.DataRequired()])

	def handle (self):
		character_id = State.clients_sockets[self.websocket]
		character = models.SessionCharacter.query.filter_by(
			id = character_id,
			game_session_id = self.game_session_id.data,
			user_role = "player",
		).first()
		if not character:
			return error_response('Forbidden')

		obj = models.PlayObject.query.filter_by(id = self.obj_id.data, is_deleted = False).first()
		if not obj:
			return error_response('Object is not found')

		if obj.type != constants.PlayfieldObject.ITEM:
			return error_response('Object is not an item')

		item_id = int(obj.attrs.get('item', 0))
		item = models.SessionItem.query.get(item_id)
		if not item:
			# TODO: Delete object if this situation is occured?
			return error_response('Item is not found')

		item.owner_id = character.id
		item.add()

		obj.is_deleted = True
		obj.add()

		DBSession.commit()

		obj.add()
		item.add()
		character.add()
		items = character.get_items()

		data = {'obj_id': obj.id, 'obj_type': constants.PlayfieldObject.NAME_TO_TYPE.inv[obj.type]}
		self.group_call_client_action('DeletePlayfieldObject', data)

		return {'success': True, 'items': items}

@add_route()
class GetOnlinePlayers (ParentAction):
	game_session_id = fields.IntegerField(validators = [v.DataRequired()])

	def handle (self):
		character_id = State.clients_sockets[self.websocket]

		has_permission = models.SessionCharacter.query.filter_by(
			id = character_id,
			game_session_id = self.game_session_id.data,
		).count()
		if not has_permission:
			return error_response('Forbidden')

		_, session_id = State.clients_by_character[character_id]

		online_players_ids = []
		master = models.SessionCharacter.query.filter_by(
			game_session_id = self.game_session_id.data,
			user_role = "master"
		).first()
		master_is_online = False
		for char_id in State.clients_by_session[session_id]:
			if char_id == master.id:
				master_is_online = True
				continue
			online_players_ids.append(char_id)

		return {'success': True, 'online_players_ids': online_players_ids, 'master_is_online': master_is_online}

@add_route()
class RollDices (ParentAction):
	dices_ids= fields.FieldList(fields.IntegerField())

	def handle (self):
		dices_ids = self.dices_ids.data

		dices = models.Dice.query.filter(models.Dice.id.in_(dices_ids))
		dices = dict([(d.id, d) for d in dices])

		results = []
		for dice_id in dices_ids:
			if dice_id not in dices:
				continue
			dice = dices[dice_id]
			results.append({'id': dice.id, 'value': dice.roll()})

		self.group_call_client_action('RollDiceResults', {'results': results}, True)

		return {
			'success': True,
			'request_id': self.request_id.data,
			'results': results,
		}


@add_route()
class CharactersAddXp (ParentAction):
	class XpForm (ParentForm):
		character_id = fields.IntegerField(validators = [v.DataRequired()])
		character_xp = fields.IntegerField(validators = [v.DataRequired()])

	game_session_id = fields.IntegerField(validators = [v.DataRequired()])
	xp = fields.FieldList(fields.FormField(XpForm))

	def handle (self):
		master_id = State.clients_sockets[self.websocket]
		is_master = models.SessionCharacter.query.filter_by(
			id = master_id,
			game_session_id = self.game_session_id.data,
			user_role = "master",
		).count()
		if not is_master:
			return error_response('Forbidden')

		session_characters = models.SessionCharacter.query.filter_by(
			game_session_id = self.game_session_id.data,
			user_role = "player",
		)
		players_ids = [session_character.id for session_character in session_characters]

		updated_characters = []

		for xp_info in self.xp.data:
			character_id = xp_info['character_id']
			character_xp = xp_info['character_xp']

			if character_id not in players_ids:
				# TODO: Validation error?
				continue

			character = models.SessionCharacter.query.filter_by(
				id = character_id,
				game_session_id = self.game_session_id.data,
				user_role = "player",
			).first()

			if not character:
				continue

			character.gain_xp(character_xp)
			character.add()

			updated_characters.append(character)

		DBSession.commit()
		DBSession.add_all(updated_characters)

		character_params = {char.id: char.as_dict() for char in updated_characters}

		self.group_call_client_action('CharactersXpChanged', {'characters': character_params}, include_sender = True)

		return {
			'success': True,
			'request_id': self.request_id.data,
		}
