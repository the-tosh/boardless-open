# _*_ encoding: utf-8 _*_

import ast

from sapyens.helpers import route_view_config

from pyramid.httpexceptions import HTTPUnprocessableEntity, HTTPFound

from boardless import forms
from boardless import helpers as h
from boardless import constants
from boardless.libs import formula
from boardless.db import models, DBSession

COLORS = [
	'#000000',
	'#ff0000',
	'#00ff00',
	'#0000ff',
	'#ffff00',
	'#ff00ff',
	'#ffffff',
	'#a3a3a3',
]

def _get_cols_for_characters_table (rules):
	# List of tuples (column_title, field_owner, field_name)
	fields = [('Nickname', 'player', 'name'), ('Level', 'player', 'level'), ('XP', 'player', 'xp')]

	fields.append(('NO CATEGORY', 'skills_category', None))
	for skill_query_tpl in rules.get_child_query_by_priority('skills').filter_by(category_id = None):
			fields.append((skill_query_tpl.Skill.title, 'skill', skill_query_tpl.Skill.id))

	for cat_query_tpl in rules.get_child_query_by_priority('skills_categories'):
		fields.append((cat_query_tpl.SkillCategory.title, 'skills_category', cat_query_tpl.SkillCategory.id))

		for skill_query_tpl in rules.get_child_query_by_priority('skills').filter_by(category_id = cat_query_tpl.SkillCategory.id):
			fields.append((skill_query_tpl.Skill.title, 'skill', skill_query_tpl.Skill.id))

	return fields

@route_view_config('/play/{game_session_id:\d+}', 'play', renderer = '/play.mako', permission = 'view')
def play (request):
	form_data = h.update_request_params(request.matchdict)
	form = forms.Play(form_data)
	if not form.validate():
		return HTTPUnprocessableEntity()

	game_session_id = form.game_session_id.data
	game_session = models.GameSession.query.filter_by(id = game_session_id, status = constants.GameSessionStatuses.AVAILABLE).first()
	if not game_session:
		return HTTPFound(location = request.route_url('games.list'))

	user_role = request.user.get_role_for_session(game_session_id)
	if user_role is None:
		return HTTPFound(location = request.route_url('games.join', game_session_id = game_session_id))


	rules_id_sq = DBSession.query(models.GameSession.rules_id).filter_by(id = game_session_id).subquery()
	rules = models.GameRules.query.filter_by(id = rules_id_sq).first()
	if not rules:
		return HTTPUnprocessableEntity()

	master = models.SessionCharacter.query.filter_by(game_session_id = game_session_id, user_role = "master").first()
	character = models.SessionCharacter.query.filter_by(game_session_id = game_session_id, user_id = request.user.id).first()

	players = []
	the_player = None
	the_player_id = -1
	character_token = None
	if not character:
		user_role = "spectator"
	elif master.id == character.id:
		user_role = "master"
		character_token = master.token
	else:
		the_player = character
		the_player_id = character.id
		players.append(character)
		user_role = "player"
		character_token = character.token

	other_players = models.SessionCharacter.query.filter(models.SessionCharacter.game_session_id == game_session_id, models.SessionCharacter.user_role == "player", models.SessionCharacter.user_id != request.user.id).order_by('id').all()
	players += other_players
	players_dicts = []
	for player in players:
		with_items = the_player is not None and player.id == the_player.id
		players_dicts.append(player.as_dict(with_items = with_items))

	cols_for_char_tbl = _get_cols_for_characters_table(rules)

	item_groups = []
	for item_group_query_tpl in rules.get_child_query_by_priority('item_groups').filter_by(is_disabled = False):
		item_groups.append({
			'id': item_group_query_tpl.ItemGroup.id,
			'title': item_group_query_tpl.ItemGroup.title,
		})

	skills_categories = [cat.as_dict() for cat in models.SkillCategory.query.filter_by(rules_id = rules.id, is_disabled = False)]

	items = [x.as_dict() for x in rules.items_query.filter_by(is_disabled = False)]

	skills = {}
	for skill in rules.skills_query.filter_by(is_disabled = False):
		skills.setdefault(skill.id, {})
		skills[skill.id].update(skill.as_dict())
		skills[skill.id].setdefault('related_skills', [])

		if skill.formula.strip() and master.id != character.id:
			node = ast.parse(skill.formula, mode = 'eval') # TODO: exceptions?
			visitor = formula.VariablesCollectionVisitor({})
			visitor.visit(node)
			related_skills = rules.skills_query.filter(models.Skill.title.in_(visitor.VARIABLE_NAMES))
			for related_skill in related_skills:
				skills.setdefault(related_skill.id, {})
				skills[related_skill.id].setdefault('related_skills', [])
				skills[related_skill.id]['related_skills'].append(skill.id)

	token_tools = []
	defaults = constants.PlayfieldObject.get_defaults(request.static_url('boardless:static/'))
	for obj_type in constants.PlayfieldObject.GENERAL_OBJECTS_ORDER:
		token_tools.append({
			'type': obj_type,
			'title': defaults[obj_type]['title'],
			'img_url': defaults[obj_type]['img_url'],
		})

	return {
		'colors': COLORS,
		'game_session_id': game_session_id,
		'the_player_id': the_player_id,
		'character_token': character_token,
		'master': master,
		'players': players_dicts,
		'cols_for_char_tbl': cols_for_char_tbl,
		'skills': skills,
		'item_groups': item_groups,
		'rules': rules,
		'user_role': user_role,
		'skills_categories': skills_categories,
		'token_tools': token_tools,

		'items': items,
		'dices': {d.id: d.as_dict(static_path = request.static_url('boardless:static/')) for d in rules.dices},

		'constants': constants,
	}