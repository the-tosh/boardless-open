from pyramid.httpexceptions import HTTPFound, HTTPBadRequest
from sapyens.helpers import route_view_config

from boardless import forms
from boardless import constants
from boardless.db import models

@route_view_config('/rules/list', 'rules.list', renderer = '/rules/list.mako', permission = 'view')
def list (request):
	user = request.user
	form = forms.GameRules(request.POST)
	return {'game_rules': user.game_rules_query.order_by('id'), 'constants': constants, 'form': form}

@route_view_config('/rules/edit/{rules_id:\d+}', 'rules.edit', renderer = '/rules/edit.mako', permission = 'view')
def edit (request):
	rules_id = request.matchdict['rules_id']
	gr = models.GameRules.query.filter_by(id = rules_id).first()
	if not gr:
		return HTTPBadRequest()

	if gr.status != constants.GameRulesStatuses.IS_MODERATING:
		return HTTPFound(location = request.route_url('rules.list'))

	form = forms.GameRules(request.POST, gr)
	if request.method == 'POST':
		if form.validate():
			form.populate_obj(gr)
			gr.dices = form.dices.data #m2m
			gr.add()

	skill_form = forms.Skill()
	skill_form.category.choices = [(None, 'No category')] + [(category.id, category.title) for category in gr.skills_categories]

	item_form = forms.ItemCreate()
	item_form.group_id.choices = [(ig.id, ig.title) for ig in gr.item_groups]

	skills_cache = {skill.id: skill.title for skill in gr.skills}

	return {
		'form': form,
		'rules': gr,
		'skill_category_form': forms.SkillCategory(),
		'skill_form': skill_form,
		# 'perk_form': forms.Perk(),
		'race_form': forms.Race(),
		'item_group_form': forms.ItemGroup(),
		'item_form': item_form,
		'class_form': forms.CharacterClass(),
		'base_dice': models.Dice,
		'skills_cache': skills_cache,
	}

@route_view_config('/rules/view/{rules_id:\d+}', 'rules.view', renderer = '/rules/view.mako', permission = 'view')
def view (request):
	rules_id = request.matchdict['rules_id']
	gr = models.GameRules.query.filter_by(id = rules_id).first()
	if not gr:
		return HTTPBadRequest()

	if gr.status != constants.GameRulesStatuses.AVAILABLE:
		return HTTPFound(location = request.route_url('rules.list'))

	form = forms.GameRules(obj = gr)
	skills_cache = {skill.id: skill.title for skill in gr.skills}

	return {
		'rules': gr,
		'form': form,
		'skills_cache': skills_cache,
	}

@route_view_config('/rules/finalize/{rules_id:\d+}', 'rules.finalize', renderer = 'string', permission = 'view')
def finalize (request):
	rules_id = request.matchdict['rules_id']
	gr = models.GameRules.query.filter_by(id = rules_id, creator_id = request.user.id).first()
	if not gr:
		return HTTPFound(location = request.route_url('rules.list'))

	gr.status = constants.GameRulesStatuses.AVAILABLE
	gr.add()

	return HTTPFound(location = request.route_url('rules.list'))
