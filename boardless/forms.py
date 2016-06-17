# _*_ encoding: utf-8 _*_

from boardless import constants
from boardless.db import models, DBSession
from boardless.libs import formula

import ast
import itertools

from string import strip
from markupsafe import escape

from wtforms.ext.sqlalchemy.fields import QuerySelectField, QuerySelectMultipleField
from wtforms.validators import *
from wtforms.validators import ValidationError
from wtforms.form import Form
from wtforms import fields
from wtforms import widgets

RULES_CHILD_TYPES = ('skill', 'skills_category', 'item_group', 'item', 'race', 'character_class')

STRING_OUTPUT_FILTERS = (strip, escape, unicode)
FORMULA_FILTERS = (strip, unicode)
BOOLEAN_FALSE_VALUES = ('false', '0', '', None)
INT4_MAX_VALUE = 2147483647

# TODO: DatabaseRowExistsValidator -> custom field

#############################################
# Custom fields
#############################################

class CustomFieldList (fields.FieldList):
	def validate (self, form, extra_validators = tuple()):
		self.errors = {}
		for i, subfield in enumerate(self.entries):
			if not subfield.validate(form):
				for fieldname, errors_list in subfield.errors.viewitems():
					if errors_list:
						key = '{}-{}-{}'.format(self.name, i, fieldname)
						self.errors.setdefault(key, [])
						self.errors[key] += errors_list

		chain = itertools.chain(self.validators, extra_validators)
		self._run_validation_chain(form, chain)

		return len(self.errors) == 0

#############################################
# Custom validators
#############################################

class DatabaseRowExistsValidator (object):
	def __init__ (self, model, field_name = None, message = None):
		self.message = message
		self.model = model
		self.field_name = field_name

	def _get_message (self, field_name):
		if self.message is None:
			return "{0} does not exist".format(field_name[0].upper() + field_name[1:])
		return self.message

	def __call__ (self, form, field):
		field_name = self.field_name or field.name
		model_field = getattr(self.model, field_name)
		obj = self.model.query.filter(model_field == field.data).first()

		if not obj:
			message = self._get_message(field_name)
			raise ValidationError(message)

class DatabaseRowUniqueValidator (object):
	def __init__ (self, model, filter_fields = None, exclude_field_name = None, message = 'Exists already'):
		self.exclude_field_name = exclude_field_name
		self.filter_fields = filter_fields or []
		self.model = model
		self.message = message

	def __call__ (self, form, field):
		model_field = getattr(self.model, field.name)

		query = (self.model.query
			.filter(model_field == field.data)
		)

		for field_name in self.filter_fields:
			model_field = getattr(self.model, field_name)
			form_field = getattr(form, field_name)
			query = query.filter(model_field == form_field.data)

		if self.exclude_field_name:
			model_exclude_field = getattr(self.model, self.exclude_field_name)
			query = query.filter(model_exclude_field != form.data[self.exclude_field_name])

		if query.count():
			raise ValidationError(self.message)

class UserPasswordValidator (object):
	def __call__ (self, form, field):
		obj = models.User.query.filter(models.User.email == form.data['email']).first()

		if not obj:
			return

		if not obj.check_password(password = field.data):
			raise ValidationError('Incorrect password')

class GreaterOrEqualToValidator (object):
	def __init__ (self, compare_with_field_name, message = "Field1 must be greater then field2"):
		self.compare_with_field_name = compare_with_field_name
		self.message = message

	def __call__ (self, form, field):
		compare_with_field = getattr(form, self.compare_with_field_name)
		is_valid = isinstance(field.data, int) and isinstance(compare_with_field.data, int)
		if not is_valid or field.data < compare_with_field.data:
			raise ValidationError(self.message)

class NoSpacesValidator (object):
	def __call__ (self, form, field):
		if ' ' in field.data:
			raise ValidationError("Field must not contain whitespaces")

class FormulaGenericValidator (object):
	def __init__ (self, dynamic_keywords):
		self.dynamic_keywords = []

	def get_formula_variable_names (self, input_formula):
		try:
			node = ast.parse(input_formula, mode = 'eval')
		except Exception:
			# TODO: Important problem! AST can not parse unicode names as variables!
			raise ValidationError("Invalid formula") # TODO: more verbosity
		visitor = formula.VariablesCollectionVisitor(self.dynamic_keywords)
		visitor.visit(node)

		return visitor.VARIABLE_NAMES

class FormulaVariablesValidator (FormulaGenericValidator):
	def __init__ (self, dynamic_keywords):
		self.dynamic_keywords = dynamic_keywords

	def __call__ (self, form, field):
		variable_names = self.get_formula_variable_names(field.data)

		invalid_names = set(variable_names) - set(self.dynamic_keywords)
		if invalid_names:
			# TODO: Incorrect position if a title contains another title and both of them are not found
			sorted_desc_data = sorted([(name, field.data.find(name)) for name in invalid_names], key = lambda x: x[1])
			lines_desc_str = ", ".join("{0} (position {1})".format(*name) for name in sorted_desc_data)
			error_string = "Following variables are invalid: {0}".format(lines_desc_str)

			raise ValidationError(error_string)

# TODO: use this validator for skill.edit view
class FormulaLoopValidator (FormulaGenericValidator):
	def __init__ (self, skill, rules_id):
		self.skill = skill
		self.rules_id = rules_id

	def validate (self):
		self.looped_skills = []
		self.validate_skill(self.skill)

		if self.looped_skills:
			looped_skill_titles = ", ".join([st.title for st in self.looped_skills])
			error_string = "Following skills have loops in their formulas: {0}".format(looped_skill_titles)
			raise ValidationError(error_string)

		return {'success': True}

	def validate_skill (self, skill):
		if not skill.formula:
			return

		self.dynamic_keywords = [skill.title,]
		variable_names = self.get_formula_variable_names(skill.formula)

		parent_skills = DBSession.query(models.Skill).filter(
			models.Skill.rules_id == self.rules_id,
			models.Skill.title.in_(variable_names)
		)

		for parent_skill in parent_skills:
			self.validate_skill(parent_skill)

#############################################
# Filters
#############################################

def int_or_None (val):
	# TODO: Is there slighter way to emulate coerc for None values?

	if val == 'None':
		return
	return int(val)

#############################################
# Forms
#############################################

class FieldForm (Form):
	''' Dummy class for FormField, "_"-prefixed forms '''
	pass

class ParentForm (Form):
	@property
	def errors (self):
		errors_dict = {}
		for fieldname, field in self._fields.viewitems():
			field_errors = field.errors

			if isinstance(field_errors, list) and field_errors:
				errors_dict[fieldname] = field_errors

			elif isinstance(field_errors, dict) and field_errors:
				for subfield_name, subfield_errors in field_errors.viewitems():
					errors_dict[subfield_name] = subfield_errors

		if self._errors is None:
			self._errors = {
				'success': False,
				'errors': errors_dict, # dict((name, f.errors) for name, f in self._fields.iteritems() if f.errors)
			}

		return self._errors

class PageForm (ParentForm):
	LIMIT = 20

	def __init__ (self, formdata = None, obj = None, prefix = '', data = None, meta = None, pages_total = None, **kwargs):
		if not pages_total:
			raise Exception('Total pages number has not been passed')

		self.pages_total = pages_total
		return super(PageForm, self).__init__(formdata = formdata, obj = obj, prefix = prefix, data = data, meta = meta, **kwargs)


	page = fields.IntegerField(default = 1, validators = [DataRequired()])

class _SkillMod (FieldForm):
	skill_id = fields.IntegerField(validators = [DataRequired()])
	mod = fields.IntegerField(validators = [DataRequired()])

class _SkillModZeroAllowed (FieldForm):
	skill_id = fields.IntegerField(validators = [DataRequired()])
	mod = fields.IntegerField(validators = [InputRequired(), NumberRange(min = 0, max = INT4_MAX_VALUE)])

class AuthLogin (ParentForm):
	email = fields.StringField(default = '', filters = [strip], validators = [DataRequired(), Email(), DatabaseRowExistsValidator(models.User)])
	password = fields.StringField(validators = [DataRequired(), Length(max = 255), UserPasswordValidator()])

class AuthRegistration (ParentForm):
	email = fields.StringField(default = '', filters = [strip], validators = [DataRequired(), Email(), DatabaseRowUniqueValidator(models.User)])
	password = fields.PasswordField(validators = [DataRequired(), Length(max = 255)])
	password_confirm = fields.PasswordField(validators = [DataRequired(), Length(max = 255), EqualTo('password')])
	nickname = fields.StringField(default = '', filters = STRING_OUTPUT_FILTERS, validators = [DataRequired(), Length(max = 255),  DatabaseRowUniqueValidator(models.User)])
	invite = fields.StringField(default = '', filters = [strip], validators = [DataRequired()])

	def validate_invite (self, field):
		_hash = field.data

		obj = models.BetaInvite.query.filter_by(hash = _hash, is_used = False).first()
		if not obj:
			raise ValidationError("Invalid invite code")
		if obj.is_used:
			raise ValidationError("This invite has already been used")

class AuthRestorePasswordRequest (ParentForm):
	email = fields.StringField(default = '', filters = [strip], validators = [DataRequired(), Email(), DatabaseRowExistsValidator(models.User)])

class AuthRestorePassword (ParentForm):
	req_hash = QuerySelectField(allow_blank = False, get_pk = lambda x: x.hash)
	password = fields.PasswordField(validators = [DataRequired(), Length(max = 255)])
	password_confirm = fields.PasswordField(validators = [DataRequired(), Length(max = 255), EqualTo('password')])

class SkillCategory (ParentForm):
	rules_id = fields.IntegerField(validators = [DataRequired()])
	title = fields.StringField(default = '', filters = STRING_OUTPUT_FILTERS, validators = [DataRequired(), Length(max = 255)])
	base_value = fields.IntegerField(default = 0, validators = [InputRequired(), NumberRange(min = 0, max = INT4_MAX_VALUE)])

class Skill (ParentForm):
	rules_id = fields.IntegerField(validators = [DataRequired()])
	title = fields.StringField(default = '', filters = STRING_OUTPUT_FILTERS, validators = [
				NoSpacesValidator(),
				DataRequired(),
				Length(max = 255),
				DatabaseRowUniqueValidator(models.Skill, filter_fields = ['rules_id'])
		]
	)
	category = fields.SelectField(filters = [int_or_None], validators = [Optional()])
	base_value = fields.IntegerField(default = 0, validators = [InputRequired(), NumberRange(min = 0, max = INT4_MAX_VALUE)])
	max_value = fields.IntegerField(default = 10, validators = [InputRequired(), NumberRange(min = 0, max = INT4_MAX_VALUE), GreaterOrEqualToValidator('base_value', message = "Max value must be greater then base value")])
	formula = fields.TextAreaField(default = '', id = 'skills-formula', filters = FORMULA_FILTERS, validators = [Optional()])

	def validate_formula (self, field):
		rules_id = self._fields['rules_id'].data or -1
		skills = models.Skill.query.filter_by(rules_id = rules_id)

		validator = FormulaVariablesValidator([s.title for s in skills])
		validator(self, field)

class Perk (ParentForm):
	rules_id = fields.IntegerField(validators = [DataRequired()])
	title = fields.StringField(default = '', filters = STRING_OUTPUT_FILTERS, validators = [DataRequired(), Length(max = 255)]) # TODO: Title uniqueness?
	description = fields.StringField(default = '', filters = STRING_OUTPUT_FILTERS, validators = [Optional(), Length(max = 255)], widget = widgets.TextArea())
	skills = CustomFieldList(fields.FormField(_SkillMod), min_entries = 0)

class Race (ParentForm):
	rules_id = fields.IntegerField(validators = [DataRequired()])
	title = fields.StringField(default = '', filters = STRING_OUTPUT_FILTERS, validators = [DataRequired(), Length(max = 255)]) # TODO: Title uniqueness?
	skills = CustomFieldList(fields.FormField(_SkillMod), min_entries = 0)

class RaceEdit (Race):
	race_id = fields.IntegerField(validators = [DataRequired()])

class ItemGroup (ParentForm):
	rules_id = fields.IntegerField(validators = [DataRequired()])
	title = fields.StringField(default = '', filters = STRING_OUTPUT_FILTERS, validators = [DataRequired(), Length(max = 255)])
	max_worn_items = fields.IntegerField(default = 1, validators = [InputRequired(), NumberRange(min = 1, max = INT4_MAX_VALUE)])
	is_equippable = fields.BooleanField(false_values = BOOLEAN_FALSE_VALUES)
	is_usable = fields.BooleanField(false_values = BOOLEAN_FALSE_VALUES)
	has_charge = fields.BooleanField(false_values = BOOLEAN_FALSE_VALUES)
	has_durability = fields.BooleanField(false_values = BOOLEAN_FALSE_VALUES)
	has_damage = fields.BooleanField(false_values = BOOLEAN_FALSE_VALUES)

class ItemGroupToggleAttribute (ParentForm):
	rules_id = fields.IntegerField(validators = [DataRequired()])
	item_group = QuerySelectField(allow_blank = False)
	attr_name = fields.SelectField(choices = [('is_equippable', 'is_equippable'), ('is_usable', 'is_usable'), ('has_charge', 'has_charge'), ('has_durability', 'has_durability'), ('has_damage', 'has_damage'), ('is_disabled', 'is_disabled')], coerce = str)

class Item (ParentForm):
	title = fields.StringField(default = '', filters = STRING_OUTPUT_FILTERS, validators = [DataRequired(), Length(max = 255), DatabaseRowUniqueValidator(models.Item, filter_fields = ['rules_id'])])
	slots_consumed = fields.IntegerField(default = 1, validators = [Optional(), NumberRange(min = 1, max = INT4_MAX_VALUE)])
	# max_charge = fields.IntegerField(default = 1, validators = [InputRequired(), NumberRange(min = 1, max = INT4_MAX_VALUE)])
	# max_durability = fields.IntegerField(default = 1, validators = [InputRequired(), NumberRange(min = 1, max = INT4_MAX_VALUE)])
	# damage_formula = fields.TextAreaField(default = '', filters = STRING_OUTPUT_FILTERS, validators = [Optional()]) # TODO: Formula validator
	skills = CustomFieldList(fields.FormField(_SkillMod), min_entries = 0)

class ItemCreate (Item):
	rules_id = fields.IntegerField(validators = [DataRequired()])
	group_id = fields.SelectField(validators = [DataRequired()], coerce = int)

class ItemEdit (ItemCreate):
	id = fields.IntegerField(validators = [DataRequired(), DatabaseRowExistsValidator(models.Item)])
	title = fields.StringField(default = '', filters = STRING_OUTPUT_FILTERS, validators = [DataRequired(), Length(max = 255), DatabaseRowUniqueValidator(models.Item, filter_fields = ['rules_id'], exclude_field_name = 'id')])

class ItemInfo (ParentForm):
	id = fields.IntegerField(validators = [DataRequired(), DatabaseRowExistsValidator(models.Item)])

class GameRules (ParentForm):
	title = fields.StringField(default = '', filters = STRING_OUTPUT_FILTERS, validators = [DataRequired(), Length(max = 255)])
	max_players = fields.IntegerField(default = constants.GameRulesCommon.MAX_PLAYERS, validators = [InputRequired(), NumberRange(min = 2, max = constants.GameRulesCommon.MAX_PLAYERS)])
	dices = QuerySelectMultipleField(query_factory = lambda: models.Dice.query, allow_blank = True)
	# base_perk_points = fields.IntegerField(default = 0, validators = [InputRequired(), NumberRange(min = 0, max = INT4_MAX_VALUE)])

class GameRulesChildChangeStatus (ParentForm):
	id = fields.IntegerField(validators = [DataRequired(), NumberRange(min = 1)])
	disable = fields.BooleanField(false_values = BOOLEAN_FALSE_VALUES)
	child_type = fields.StringField(validators = [InputRequired(), AnyOf(RULES_CHILD_TYPES)])

class CreateGameSession (ParentForm):
	rules_id = fields.IntegerField(validators = [DataRequired()])

class CharacterApplyChanges (ParentForm):
	class _SkillToApply (FieldForm):
		id = fields.IntegerField(validators = [DataRequired()])
		value = fields.IntegerField(validators = [InputRequired()])

	game_session_id = fields.IntegerField(validators = [DataRequired()])
	skills = fields.FieldList(fields.FormField(_SkillToApply), min_entries = 1)

class JoinGameSession (ParentForm):
	game_session_id = fields.IntegerField(validators = [DataRequired()])
	user_id = fields.IntegerField(validators = [DataRequired()])

class Play (ParentForm):
	game_session_id = fields.IntegerField(validators = [DataRequired()])

class CharacterClass (ParentForm):
	rules_id = fields.IntegerField(validators = [DataRequired()])
	title = fields.StringField(label = "Title", default = '', filters = STRING_OUTPUT_FILTERS, validators = [DataRequired(), Length(max = 255)]) # TODO: Title uniqueness?
	skills = CustomFieldList(fields.FormField(_SkillMod), min_entries = 0)

class CreateSessionCharacter (ParentForm):
	game_session_id = fields.IntegerField(validators = [DataRequired()])
	name = fields.StringField(validators = [DataRequired(), DatabaseRowUniqueValidator(models.SessionCharacter, filter_fields = ['game_session_id'], message = 'This nickname already taken in this session')])
	race = QuerySelectField(allow_blank = True, blank_text = "Choose a race", get_label = lambda x: x.title)
	cls = QuerySelectField(allow_blank = True, blank_text = "Choose a class", get_label = lambda x: x.title)
	skills = CustomFieldList(fields.FormField(_SkillModZeroAllowed), min_entries = 0)

	def validate_race (form, field):
		if field.query.count():
			if field.data is None:
				raise ValidationError("Please, choose a race")

	def validate_cls (form, field):
		if field.query.count():
			if field.data is None:
				raise ValidationError("Please, choose a class")

class ProfilePasswordChange (ParentForm):
	email = fields.StringField(default = '', filters = [strip], validators = [DataRequired(), Email(), DatabaseRowExistsValidator(models.User)])
	password_old = fields.PasswordField(label = 'Old password', validators = [DataRequired(), Length(max = 255), UserPasswordValidator()])
	password = fields.PasswordField(label = 'New password', validators = [DataRequired(), Length(max = 255)])
	password_confirm = fields.PasswordField(label = 'Repeat new password', validators = [DataRequired(), Length(max = 255), EqualTo('password')])

class AddDices (ParentForm):
	rules_id = fields.IntegerField(validators = [DataRequired()])
	dice_id = QuerySelectMultipleField(query_factory = lambda: models.Dice.query, allow_blank = True)

class CharacterLevels (ParentForm):
	class _LevelSettings (FieldForm):
		rules_id = fields.IntegerField(validators = [DataRequired()])
		xp = fields.IntegerField(default = 0, validators = [InputRequired(), NumberRange(min = 0, max = INT4_MAX_VALUE)])
		# perks_formula = fields.StringField(default = '', filters = FORMULA_FILTERS, validators = [InputRequired()])

		def validate_perks_formula (self, field):
			rules_id = self._fields['rules_id'].data or -1
			skills = models.Skill.query.filter_by(rules_id = rules_id)

			validator = FormulaVariablesValidator([s.title for s in skills])
			validator(self, field)

	class _SkillsCategoryFormula (FieldForm):
		level = fields.IntegerField(validators = [DataRequired(), NumberRange(min = 0, max = 100)])
		category_id = fields.IntegerField(validators = [DataRequired()])
		formula = fields.StringField(default = '', filters = FORMULA_FILTERS, validators = [InputRequired()])

		def validate_formula (self, field):
			category_id = self._fields['category_id'].data or -1
			skills = models.Skill.query.filter_by(category_id = category_id)

			validator = FormulaVariablesValidator([s.title for s in skills])
			validator(self, field)

	rules_id = fields.IntegerField(validators = [DataRequired()])
	level_settings = CustomFieldList(fields.FormField(_LevelSettings), min_entries = 1, max_entries = 100)
	skills_categories_formulas = CustomFieldList(fields.FormField(_SkillsCategoryFormula), min_entries = 0, max_entries = 100)

class Feedback (ParentForm):
	MESSAGE_TYPES = {
		'bug': 'Bug report',
		'feature': 'Feature request',
		'message': 'Message',
	}

	subject = fields.StringField(default = '', filters = STRING_OUTPUT_FILTERS, validators = [DataRequired()])
	message_type = fields.SelectField(validators = [DataRequired()], choices = [(k, v) for k, v in MESSAGE_TYPES.viewitems()])
	message = fields.StringField(default = '', filters = STRING_OUTPUT_FILTERS, validators = [DataRequired()])
	page = fields.StringField(default = '', validators = [DataRequired()])

#############################################
# Admin
#############################################

class AdminUserNew (ParentForm):
	FIELDS_ORDER = (
		('Main', ('email', 'nickname', 'group', 'password', 'status')),
	)

	email = fields.StringField(default = "", validators = [Email(), DataRequired(), DatabaseRowUniqueValidator(models.User)])
	nickname = fields.StringField(default = "", validators = [DataRequired(), DatabaseRowUniqueValidator(models.User)])
	password = fields.StringField(default = "", validators = [DataRequired()])
	status = fields.SelectField(default = constants.UserStatus.NEW, validators = [DataRequired()], choices = constants.UserStatus.CHOICES, coerce = int)
	group = fields.SelectField(choices = constants.UserGroups.CHOICES, validators = [DataRequired()], coerce = str)

class AdminUserEdit (ParentForm):
	FIELDS_ORDER = (
		('Main', ('id', 'email', 'nickname', 'group')),
	) # TODO: Show OTHER fields

	id = fields.IntegerField(validators = [DataRequired(), DatabaseRowExistsValidator(models.User)])
	email = fields.StringField(default = "", validators = [Email(), DataRequired(), DatabaseRowUniqueValidator(models.User, exclude_field_name = 'id')])
	nickname = fields.StringField(default = "", validators = [DataRequired(), DatabaseRowUniqueValidator(models.User, exclude_field_name = 'id')])
	status = fields.SelectField(default = constants.UserStatus.NEW, validators = [DataRequired()], choices = constants.UserStatus.CHOICES, coerce = int)
	group = fields.SelectField(choices = constants.UserGroups.CHOICES, validators = [DataRequired()], coerce = str)

class AdminRulesNew (ParentForm):
	FIELDS_ORDER = (
		('Main', ('title', 'creator_id', 'status')),
	)

	title = fields.StringField(default = "", validators = [DataRequired(), DatabaseRowUniqueValidator(models.GameRules)])
	creator_id = QuerySelectField(query_factory = lambda: models.User.query.order_by(models.User.id.asc()), allow_blank = False)
	status = status = fields.SelectField(default = constants.GameRulesStatuses.IS_MODERATING, validators = [DataRequired()], choices = constants.GameRulesStatuses.CHOICES, coerce = int)

class AdminRulesEdit (ParentForm):
	FIELDS_ORDER = (
		('Main', ('id', 'title', 'creator_id', 'status')),
	) # TODO: Show OTHER fields

	id = fields.IntegerField(validators = [DataRequired(), DatabaseRowExistsValidator(models.GameRules)])
	title = fields.StringField(default = "", validators = [DataRequired(), DatabaseRowUniqueValidator(models.GameRules, exclude_field_name = 'id')])
	creator_id = QuerySelectField(query_factory = lambda: models.User.query.order_by(models.User.id.asc()), allow_blank = False)
	status = fields.SelectField(default = constants.GameRulesStatuses.IS_MODERATING, validators = [DataRequired()], choices = constants.GameRulesStatuses.CHOICES, coerce = int)

class AdminInviteNew (ParentForm):
	FIELDS_ORDER = (
		('Main', ('hash',)),
	) # TODO: Show OTHER fields

	hash = fields.StringField(default = "", validators = [DataRequired(), DatabaseRowUniqueValidator(models.BetaInvite)])

class AdminInviteEdit (ParentForm):
	FIELDS_ORDER = (
		('Main', ('id', 'hash', 'is_used', 'user_id', 'activation_time', 'ctime')),
	) # TODO: Show OTHER fields

	id = fields.IntegerField(validators = [DataRequired(), DatabaseRowExistsValidator(models.BetaInvite)])
	hash = fields.StringField(default = "", validators = [DataRequired(), DatabaseRowUniqueValidator(models.BetaInvite, exclude_field_name = 'id')])
	is_used = fields.BooleanField(false_values = BOOLEAN_FALSE_VALUES)
	user_id = QuerySelectField(query_factory = lambda: models.User.query.order_by(models.User.id.asc()), allow_blank = False)
	activation_time = fields.DateTimeField(validators = [Optional()], format = '%d.%m.%Y %H:%M:%S')
	ctime = fields.DateTimeField(validators = [DataRequired()], format = '%d.%m.%Y %H:%M:%S')