# _*_ encoding: utf-8 _*_

import time
import hashlib
import random
import math

from boardless import forms
from boardless import helpers as h
from boardless import constants
from boardless.db import models, DBSession

from pyramid.httpexceptions import HTTPFound, HTTPBadRequest

from sapyens.helpers import route_view_config
from sqlalchemy import func

@route_view_config('/', 'games.list', renderer = '/games/list.mako', permission = 'view')
def list (request):
	rules = models.GameRules.query.filter_by(status = constants.GameRulesStatuses.AVAILABLE)
	return {'rules_list': rules}

@route_view_config('/games/create/{rules_id:\d+}', 'games.create', permission = 'view')
def create (request):
	form_data = h.update_request_params(request.matchdict)
	form = forms.CreateGameSession(form_data)
	if not form.validate():
		return HTTPBadRequest()

	user = request.user

	session = models.GameSession()
	form.populate_obj(session)
	session.board_image = ""
	session.status = constants.GameSessionStatuses.AVAILABLE

	session.add()

	character = models.SessionCharacter()
	character.user_id = user.id
	character.user_role = constants.SessionCharacterRoles.MASTER
	character.name = user.nickname
	character.game_session = session
	character.token = hashlib.sha256('{0}{1}{2}'.format(user.id, time.time(), random.randint(0, 1000))).hexdigest()
	character.add()

	DBSession.flush()

	return HTTPFound(location = request.route_url('play', game_session_id = session.id))

@route_view_config('/games/joinable', 'games.joinable', renderer = '/games/joinable.mako', permission = 'view')
def joinable (request):
	rules_ids_sq = DBSession.query(models.GameRules.id).order_by(models.GameRules.ctime.desc())

	joined_games_sq = DBSession.query(models.SessionCharacter.game_session_id).filter_by(user_id = request.user.id).subquery()

	rules_sessions = (DBSession.query(models.GameRules.id, models.GameRules.title, models.GameRules.max_players, func.count(models.GameSession.id).label('sessions_num'))
		.join(models.GameSession, models.GameSession.rules_id == models.GameRules.id)

		.filter(models.GameRules.id.in_(rules_ids_sq))
		.filter(models.GameRules.max_players > models.GameSession.players_joined)

		.filter(models.GameSession.status != constants.GameSessionStatuses.CLOSED)
		.filter(~models.GameSession.id.in_(joined_games_sq))

		.group_by(models.GameRules.id, models.GameRules.title, models.GameRules.max_players)
	)

	pages_total = math.ceil(rules_sessions.count() / float(forms.PageForm.LIMIT))
	if not pages_total:
		return {'rules_sessions': {}}

	form = forms.PageForm(request.GET, pages_total = pages_total)
	if not form.validate():
		return HTTPFound(location = request.route_url('games.joinable'))

	offset = (form.page.data - 1) * form.LIMIT

	rules_sessions = rules_sessions.offset(offset).limit(form.LIMIT)

	return {'rules_sessions': rules_sessions}

@route_view_config('/games/joinable/{rules_id:\d+}', 'games.joinable_rules', renderer = '/games/joinable_rules.mako', permission = 'view')
def joinable_rules (request):
	# TODO: Pagination

	joined_games_sq = DBSession.query(models.SessionCharacter.game_session_id).filter_by(user_id = request.user.id).subquery()

	sessions = (models.GameSession.query
		.join(models.GameRules, models.GameSession.rules_id == models.GameRules.id)
		.filter(
			models.GameRules.id == request.matchdict['rules_id'],

			models.GameSession.players_joined < models.GameRules.max_players,
			models.GameSession.status != constants.GameSessionStatuses.CLOSED,
			~models.GameSession.id.in_(joined_games_sq),
		)
	)

	return {'sessions': sessions}

@route_view_config('/games/joined', 'games.joined', renderer = '/games/joined.mako', permission = 'view')
def joined (request):
	# TODO: Pagination

	session_ids_sq = DBSession.query(models.SessionCharacter.game_session_id).filter_by(user_id = request.user.id).subquery()

	sessions = models.GameSession.query.filter(
		models.GameSession.id.in_(session_ids_sq),
		models.GameSession.status != constants.GameSessionStatuses.CLOSED,
	)

	characters = models.SessionCharacter.query.filter_by(user_id = request.user.id)
	session_roles = {}
	for character in characters:
		session_roles[character.game_session_id] = character.user_role

	return {'sessions': sessions, 'session_roles': session_roles}

@route_view_config('/games/join/{game_session_id:\d+}', 'games.join', renderer = '/games/join.mako', permission = 'view')
def join (request):
	user = request.user
	form_data = h.update_request_params({'user_id': user.id}, request.matchdict)
	form = forms.JoinGameSession(form_data)
	if not form.validate():
		return HTTPBadRequest()

	game_session = models.GameSession.query.filter_by(id = form.game_session_id.data, status = constants.GameSessionStatuses.AVAILABLE).first()
	if not game_session:
		return HTTPBadRequest()

	already_joined = models.SessionCharacter.query.filter_by(game_session_id = form.game_session_id.data, user_id = user.id).first()
	if already_joined:
		return HTTPFound(location = request.route_url('play', game_session_id = form.game_session_id.data))

	if game_session.players_joined >= game_session.rules.max_players:
		# TODO: Valid message?
		return HTTPFound(location = request.route_url('games.list'))

	skills_by_cat = {}
	for skill_category in game_session.rules.skills_categories:
		skills_by_cat[skill_category.id] = []
	skills_by_cat[None] = [] # No category

	for skill in game_session.rules.skills:
		skills_by_cat[skill.category_id].append(skill)

	free_skill_points = dict([(cat.id, cat.base_value) for cat in game_session.rules.skills_categories])

	rules = game_session.rules

	form_data = h.update_request_params({'game_session_id': game_session.id, 'name': request.POST.get('name', user.nickname)}, request.POST)
	create_form = forms.CreateSessionCharacter(form_data)
	create_form.race.query = rules.races_query.filter_by(is_disabled = False)
	create_form.cls.query = rules.classes_query.filter_by(is_disabled = False)

	if request.method == 'POST':
		if create_form.validate():
			return _create_character(request, create_form, game_session)

	return {
		'game_session': game_session,
		'skills_by_cat': skills_by_cat,
		'free_skill_points': free_skill_points,
		'rules': rules,
		'form': create_form
	}

def _create_character (request, form, game_session):
	character = models.SessionCharacter.query.filter_by(user_id = request.user.id, game_session_id = game_session.id).first()
	if character:
		return HTTPFound(location = request.route_url('play', game_session_id = character.game_session_id))

	skill2cat = {}
	skills = {}
	skills_with_formula = {}
	for skill in game_session.rules.skills:
		skill2cat[skill.id] = skill.category_id
		skills[skill.id] = skill.base_value

		if skill.formula:
			skills_with_formula[skill.id] = True

	points_left = {}
	for cat in game_session.rules.skills_categories_query:
		points_left[cat.id] = cat.base_value

	for skill in form.skills.data:
		skill_id = skill['skill_id']
		mod = skill['mod']
		cat_id = skill2cat[skill_id]

		if skill_id in skills_with_formula:
			continue

		if mod > points_left[cat_id] or mod == 0:
			continue

		skills[skill_id] += mod
		points_left[cat_id] -= mod

	character = models.SessionCharacter()
	character.game_session_id = game_session.id
	character.user_id = request.user.id
	character.name = form.name.data
	character.user_role = constants.SessionCharacterRoles.PLAYER
	character.skills = skills
	character.skill_points = dict((cat_id, points) for cat_id, points in points_left.viewitems())
	character.token = hashlib.sha256('{}{}'.format(time.time(), character.name.encode('utf-8'))).hexdigest()

	if form.race.data:
		character.race_id = form.race.data.id
	if form.cls.data:
		character.class_id = form.cls.data.id

	game_session.players_joined += 1
	game_session.add()

	character.add()

	return HTTPFound(location = request.route_url('play', game_session_id = character.game_session_id))

@route_view_config('/games/close/{game_session_id:\d+}', 'games.close', renderer = 'string', permission = 'view')
def close (request):
	character = models.SessionCharacter.query.filter(
		models.SessionCharacter.game_session_id == request.matchdict['game_session_id'],
		models.SessionCharacter.user_id == request.user.id,
		models.SessionCharacter.user_role == 'master',
	).first()

	if not character:
		return HTTPFound(location = request.route_url('games.joined'))

	session = character.game_session
	session.status = constants.GameSessionStatuses.CLOSED
	session.add()

	return HTTPFound(location = request.route_url('games.joined'))
