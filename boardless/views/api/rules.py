# _*_ encoding: utf-8 _*_

from sapyens.helpers import route_view_config

from boardless import forms
from boardless import constants
from boardless import helpers as h
from boardless.db import models, DBSession

RULES_CHILDREN_MODELS_MAPPER = {
	'skills_category': models.SkillCategory,
	'skill': models.Skill,
	'perk': models.Perk,
	'item_group': models.ItemGroup,
	'item': models.Item,
	'race': models.Race,
	'character_class': models.CharacterClass,
	'dice': models.Dice,
	'rules_dice': models.RulesDice,
}

@route_view_config('/api/rules/create', 'api.rules.create', renderer = 'json', permission = 'view', request_method = 'POST')
def create (request):
	# TODO: Important! Think about "revisions". If there are active sessions for the edited rules, we should create a new revision for this rules.

	form = forms.GameRules(request.POST)
	if not form.validate():
		request.response.status = 422
		return form.errors

	gr = models.GameRules()
	form.populate_obj(gr)

	gr.status = constants.GameRulesStatuses.IS_MODERATING
	gr.creator_id = request.user.id

	gr.add()

	gr.flush()

	return {'success': True, 'result': {'id': gr.id}}

@route_view_config('/api/rules/child/change_status/', 'api.rules.child.change_status', renderer = 'json', permission = 'view', request_method = 'POST')
def rules_child_disable (request):
	form = forms.GameRulesChildChangeStatus(request.POST)
	if not form.validate():
		request.response.status = 422
		return {'success': False}

	user = request.user
	child_class = RULES_CHILDREN_MODELS_MAPPER[form.child_type.data]
	item = user.owned_rules_child(form.id.data, child_class)
	if not item:
		request.response.status = 403
		return {'success': False}

	item.is_disabled = form.disable.data
	item.add()

	return {'success': True}

@route_view_config('/api/rules/skills_category/create', 'api.rules.skills_category.create', renderer = 'json', permission = 'view', request_method = 'POST')
def rules_skills_category_create (request):
	form = forms.SkillCategory(request.POST)
	if not form.validate():
		return form.errors

	rules_id = form.rules_id.data
	if not request.user.owned_rules(rules_id):
		request.response.status = 403
		return {'success': False}

	category = models.SkillCategory()
	form.populate_obj(category)
	category.add()
	DBSession.flush()

	return {'success': True, 'result': category.as_dict()}

@route_view_config('/api/rules/skill/create', 'api.rules.skill.create', renderer = 'json', permission = 'view', request_method = 'POST')
def rules_skill_create (request):
	form = forms.Skill(request.POST)
	form.category.choices = [(None, 'No category')] + [(category.id, category.title) for category in models.SkillCategory.query.filter_by(rules_id = form.rules_id.data)]

	if not form.validate():
		return form.errors

	rules_id = form.rules_id.data
	if not request.user.owned_rules(rules_id):
		request.response.status = 403
		return {'success': False}

	skill = models.Skill()
	skill.is_disabled = False # TODO: Convert skill names to IDs?
	skill.category_id = form.category.data
	form.populate_obj(skill)
	skill.add()
	DBSession.flush()

	return {'success': True, 'result': skill.as_dict()}

@route_view_config('/api/rules/perk/create', 'api.rules.perk.create', renderer = 'json', permission = 'view', request_method = 'POST')
def rules_perk_create (request):
	form_data = h.ignore_request_params_fields(request.POST)
	form = forms.Perk(form_data)
	if not form.validate():
		return form.errors

	rules_id = form.rules_id.data
	if not request.user.owned_rules(rules_id):
		request.response.status = 403
		return {'success': False}

	perk = models.Perk()
	perk.rules_id = form.rules_id.data
	perk.title = form.title.data
	perk.description = form.description.data

	if form.skills.data:
		perk_skills = perk.skills or {}

		for skill in form.skills.data:
			skill_id = skill['skill_id'] # TODO: Title?
			mod = skill['mod']

			perk_skills[skill_id] = mod

		perk.skills = perk_skills

	perk.add()
	DBSession.flush()

	return {'success': True, 'perk_id': perk.id}

@route_view_config('/api/rules/race/create', 'api.rules.race.create', renderer = 'json', permission = 'view', request_method = 'POST')
def rules_race_create (request):
	form_data = h.ignore_request_params_fields(request.POST)
	form = forms.Race(form_data)
	if not form.validate():
		return form.errors

	rules_id = form.rules_id.data
	if not request.user.owned_rules(rules_id):
		request.response.status = 403
		return {'success': False}

	race = models.Race()
	race.rules_id = form.rules_id.data
	race.title = form.title.data
	race.skills = {}

	if form.skills.data:
		race_skills = {}

		for skill in form.skills.data:
			skill_id = skill['skill_id']
			mod = skill['mod']

			race_skills[skill_id] = mod

		race.skills = race_skills

	race.add()
	DBSession.flush()

	return {'success': True, 'result': race.as_dict()}

@route_view_config('/api/rules/item_group/create', 'api.rules.item_group.create', renderer = 'json', permission = 'view', request_method = 'POST')
def rules_item_group_create (request):
	form = forms.ItemGroup(request.POST)
	if not form.validate():
		return form.errors

	rules_id = form.rules_id.data
	if not request.user.owned_rules(rules_id):
		request.response.status = 403
		return {'success': False}

	ig = models.ItemGroup()
	form.populate_obj(ig)
	ig.add()
	DBSession.flush()

	return {'success': True, 'result': ig.as_dict()}

@route_view_config('/api/rules/item_group/toggle_attribute', 'api.rules.item_group.toggle_attribute', renderer = 'json', permission = 'view', request_method = 'POST')
def rules_item_group_toggle_attribute (request):
	rules = models.GameRules.query.get(int(request.POST.get('rules_id', -1)))
	if not rules:
		request.response.status = 422
		return {'success': False}

	form = forms.ItemGroupToggleAttribute(request.POST)
	form.item_group.query = rules.item_groups_query
	if not form.validate():
		return form.errors

	rules_id = form.rules_id.data
	if not request.user.owned_rules(rules_id):
		request.response.status = 403
		return {'success': False}

	ig = form.item_group.data
	previous_value = getattr(ig, form.attr_name.data)
	setattr(ig, form.attr_name.data, not(previous_value))
	ig.add()

	return {'success': True}

@route_view_config('/api/rules/item/create', 'api.rules.item.create', renderer = 'json', permission = 'view', request_method = 'POST')
def rules_item_create (request):
	rules = models.GameRules.query.get(int(request.POST.get('rules_id', -1)))
	if not rules:
		request.response.status = 422
		return {'success': False}

	form = forms.ItemCreate(request.POST)
	form.group_id.choices = [(ig.id, ig.title) for ig in rules.item_groups]
	if not form.validate():
		return form.errors

	rules_id = form.rules_id.data
	if not request.user.owned_rules(rules_id):
		request.response.status = 403
		return {'success': False}

	item = models.Item()
	item.title = form.title.data
	item.rules_id = form.rules_id.data
	item.group_id = form.group_id.data

	attrs = {}
	attrs['slots_consumed'] = form.slots_consumed.data
	item.attrs = attrs

	item.skills = {}
	if form.skills.data:
		item_skills = {}

		for skill in form.skills.data:
			skill_id = skill['skill_id']
			mod = skill['mod']

			item_skills[skill_id] = mod

		item.skills = item_skills

	item.add()
	DBSession.flush()

	return {'success': True, 'result': item.as_dict()}

@route_view_config('/api/rules/item/edit', 'api.rules.item.edit', renderer = 'json', permission = 'view', request_method = 'POST')
def rules_item_edit (request):
	rules = models.GameRules.query.get(int(request.POST.get('rules_id', -1)))
	if not rules:
		request.response.status = 422
		return {'success': False}

	form = forms.ItemEdit(request.POST)
	form.group_id.choices = [(ig.id, ig.title) for ig in rules.item_groups]
	if not form.validate():
		return form.errors

	group = models.ItemGroup.query.filter_by(id = form.group_id.data, rules_id = rules.id).first()

	item = models.Item.query.filter_by(id = form.id.data).first()
	item.title = form.title.data
	item.group_id = form.group_id.data

	attrs = {}
	if group.is_equippable:
		attrs['slots_consumed'] = form.slots_consumed.data
	item.attrs = attrs

	item.skills = {}
	item.add()

	return {'success': True, 'item_info': item.as_dict()}

@route_view_config('/api/item/info', 'api.rules.item.info', renderer = 'json', permission = 'view', request_method = 'GET')
def rules_item_info (request):
	form = forms.ItemInfo(request.GET)
	if not form.validate():
		return form.errors

	item = models.Item.query.filter_by(id = form.id.data).first()

	return {'success': True, 'item_info': item.as_dict()}

@route_view_config('/api/rules/class/create', 'api.rules.class.create', renderer = 'json', permission = 'view', request_method = 'POST')
def rules_class_create (request):
	form_data = h.ignore_request_params_fields(request.POST)
	form = forms.CharacterClass(form_data)
	if not form.validate():
		return form.errors

	rules_id = form.rules_id.data
	if not request.user.owned_rules(rules_id):
		request.response.status = 403
		return {'success': False}

	char_class = models.CharacterClass()
	char_class.rules_id = form.rules_id.data
	char_class.title = form.title.data
	char_class.skills = {}

	if form.skills.data:
		class_skills = {}

		for skill in form.skills.data:
			skill_id = skill['skill_id'] # TODO: Title?
			mod = skill['mod']

			class_skills[skill_id] = mod

		char_class.skills = class_skills

	char_class.add()
	DBSession.flush()

	return {'success': True, 'result': char_class.as_dict()}

@route_view_config('/api/rules/dices/choose', 'api.rules.dices.choose', renderer = 'json', permission = 'view', request_method = 'POST')
def rules_dices_choose (request):
	form = forms.AddDices(request.POST)
	if not form.validate():
		return form.errors

	dices = form.dice_id.data
	rules_id = form.rules_id.data

	rules = models.GameRules.query.get(rules_id)
	if not rules:
		request.response.status = 422
		return {'success': False}

	rules.dices = dices
	rules.add()
	DBSession.flush()

	return {'success': True}

@route_view_config('/api/rules/character_levels', 'api.rules.character.levels', renderer = 'json', permission = 'view', request_method = 'POST')
def rules_character_levels (request):
	form = forms.CharacterLevels(request.POST)
	if not form.validate():
		return form.errors

	rules_id = form.rules_id.data
	rules = models.GameRules.query.get(rules_id)
	if not rules:
		request.response.status = 422
		return {'success': False}

	levels = []
	for lvl, level_settings in enumerate(form.level_settings.data):
		if level_settings['xp'] is None:
			break

		levels.append({
			'level': lvl + 1,
			'xp': level_settings['xp'],
			# 'perks_formula': level_settings['perks_formula'],
		})

	for skills_category_formula in form.skills_categories_formulas.data:
		level = skills_category_formula['level']
		if len(levels) > level:
			continue

		category_id = skills_category_formula['category_id']
		formula = skills_category_formula['formula']

		level_settings = levels[level - 1]
		level_settings.setdefault('skills_categories_formulas', {})
		level_settings['skills_categories_formulas'][category_id] = formula

		# TODO: Could i-th element of list "levels" sets up a level differs from i-th?
		# For example: [{...}, {...}, {'level': 500, ...}, {...}]
		# The 3rd element is for 500th level

	rules.level_settings = levels
	rules.add()
	DBSession.flush()

	return {'success': True}
