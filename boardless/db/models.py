import hashlib
import random
import os

from passlib.hash import sha256_crypt

from sqlalchemy import func, Boolean
from sqlalchemy.orm import relation, joinedload
from sqlalchemy.orm.attributes import flag_modified

from boardless import constants
from boardless.libs import formula
from boardless.db import Model, DBSession

# TODO Add a warning message which says that NO-CATEGORY skills can not be increased/decreased.

class BetaInvite (Model):
	__tablename__ = 'beta_invites'

class RestorePasswordRequest (Model):
	__tablename__ = 'restore_password_requests'
	user = relation('User')

class User (Model):
	__tablename__ = 'users'
	game_rules_query = relation('GameRules', lazy = 'dynamic')

	def set_password (self, password):
		self.password = sha256_crypt.encrypt(password)

	def check_password (self, password):
		return sha256_crypt.verify(password, self.password)

	def owned_rules (self, rules_id):
		return GameRules.query.filter_by(creator_id = self.id, id = rules_id).first()

	def owned_rules_child (self, child_id, child_class):
		rules_subquery = DBSession.query(GameRules.id).filter_by(creator_id = self.id).subquery()
		return child_class.query.filter(child_class.rules_id.in_(rules_subquery), child_class.id == child_id).first()

	def get_next_rules_child_priority (self, rules_id, child_class):
		priority = DBSession.query(child_class.priority + 1).filter(child_class.rules_id == rules_id).order_by('-priority').limit(1).scalar() or 0
		return priority

	def get_role_for_session (self, game_session_id):
		return DBSession.query(SessionCharacter.user_role).filter(SessionCharacter.user_id == self.id, SessionCharacter.game_session_id == game_session_id).scalar()

	def is_game_master (self, game_session_id):
		session_role = self.get_role_for_session(game_session_id)
		return session_role and session_role == "master"

	def get_gravatar_link (self, size = 80):
		return 'http://gravatar.com/avatar/{0}?s={1}'.format(hashlib.md5(self.email.strip().lower()).hexdigest(), size)

	def __repr__ (self):
		return u"<User #{0}. Nick: {1}. Email: {2}>".format(self.id, self.nickname, self.email)

class GameRules (Model):
	__tablename__ = 'game_rules'
	creator = relation('User', backref = 'game_rules')
	skills_query = relation('Skill', lazy = 'dynamic')
	item_groups_query = relation('ItemGroup', lazy = 'dynamic')
	items_query = relation('Item', lazy = 'dynamic')
	races_query = relation('Race', lazy = 'dynamic')
	classes_query = relation('CharacterClass', lazy = 'dynamic')
	skills_categories_query = relation('SkillCategory', lazy = 'dynamic')

	sessions = relation('GameSession', backref = 'rules')
	sessions_query = relation('GameSession', lazy = 'dynamic')

	dices = relation('Dice', secondary = 'game_rules__dices', backref = 'rules')

	# JSON fields format
	# level_settings
	# 	[{'level': 1, 'xp': 100, 'perks_formula': 'level / 2', 'skills_categories_formulas': {<category_id1>: '"str" * 3', <category_id2>: '10'}}]

	def get_child_query_by_priority (self, child_name):
		CHILD_NAME_TO_MODEL_MAPPER = {
			'skills_categories': SkillCategory,
			'skills': Skill,
			'perks': Perk,
			'items': Item,
			'item_groups': ItemGroup,
			'races': Race,
			'character_class': CharacterClass,
			'dices': Dice,
		}

		_model = CHILD_NAME_TO_MODEL_MAPPER[child_name]

		# partition_by = rules_id ?
		return DBSession.query(_model, func.row_number().over(order_by = _model.priority).label('_priority')).filter_by(rules_id = self.id)

	def get_level(self, xp):
		try:
			level_info = self.level_settings[0]
		except IndexError:
			return None
		for level in self.level_settings:
			if xp >= level['xp']:
				level_info = level
				continue
			break
		return level_info['level']

	def get_level_info(self, level):
		for level_info in self.level_settings:
			if level_info['level'] == level:
				return level_info

		return None

class Skill (Model):
	__tablename__ = 'skills'
	game_rules = relation('GameRules', backref = 'skills')

	# NOTES
	# 1. Skills can relate to each other via their formulas.
	# 2. We don't support chains of relations: a skill can relate only to _base_ value of another skills in its formula. So skill chain A -> B -> C can not be implemented because incrementing skill B by incrementing skill A will affect _effective_ value of skill B, but skill C is not related to effective value of skill B
	# 3. At the moment if a skill has formula, it can not be changed directly (this way we can prevent an ambiguous behaviour in formula calculation). This feature may be implemented later.

	def get_category (self):
		return SkillCategory.query.filter_by(id = self.category_id, rules_id = self.rules_id).first()

	def as_dict (self):
		return {
			'id': self.id,
			'title': self.title,
			'is_disabled': self.is_disabled,
			'base_value': self.base_value,
			'max_value': self.max_value,
			'formula': self.formula,
			'category_id': self.category_id,
		}

class Perk (Model):
	__tablename__ = 'perks'
	game_rules = relation('GameRules', backref = 'perks')

	# JSON fields format
	# 1. skills
	# {skill1: '3 * level', skill2: '-15', skill3: 'skill2'}

	def as_dict (self):
		return {
			'id': self.id,
			'title': self.title,
			'skills': self.skills,
		}

class SkillCategory (Model):
	__tablename__ = 'skills_categories'
	game_rules = relation('GameRules', backref = 'skills_categories')

	def as_dict (self):
		return {
			'id': self.id,
			'title': self.title,
		}

class ItemGroup (Model):
	__tablename__ = 'item_groups'
	game_rules = relation('GameRules', backref = 'item_groups')
	items = relation('Item', backref = 'item_group')
	items_query = relation('Item', lazy = 'dynamic')

	def as_dict (self):
		return {
			'id': self.id,
			'rules_id': self.rules_id,
			'title': self.title,
			'has_charge': self.has_charge,
			'has_damage': self.has_damage,
			'has_durability': self.has_durability,
			'is_equippable': self.is_equippable,
			'is_usable': self.is_usable,
			'is_disabled': self.is_disabled
		}

class Item (Model):
	__tablename__ = 'items'
	game_rules = relation('GameRules', backref = 'items')
	session_items_query = relation('SessionItem', lazy = 'dynamic')

	# JSON fields format
	# 1. attrs
	# {slots_consumed: false, max_charge: 1, max_durability: 100, damage: '10 + 2d6', is_stackable: true, stack_limit: 100}
	# If stack_limit is not presented, there is no limit to stack
	# 2. skills
	# {skill1: '3 * level', skill2: '-15', skill3: 'skill2'}

	def as_dict (self):
		return {
			'id': self.id,
			'title': self.title,
			'group_id': self.group_id,
			'attrs': self.attrs,
			'skills': self.skills,
		}

class SessionItem (Model):
	__tablename__ = 'session_items'
	game_rules = relation('GameRules', backref = 'session_items')
	item = relation('Item')

	# JSON fields format
	# 1. attrs
	# {'is_equipped': true, 'is_used': false, ...}

	# Available attributes:
	# 	is_equipped
	# 	is_used
	# 	durability

class Race (Model):
	__tablename__ = 'races'
	game_rules = relation('GameRules', backref = 'races')
	# JSON fields format
	# 1. skills
	# {skill1_id: '3 * level', skill2_id: '-15', skill3_id: skill2_name}

	def as_dict (self):
		return {
			'id': self.id,
			'title': self.title,
			'skills': self.skills,
			'is_disabled': self.is_disabled
		}

class GameSession (Model):
	__tablename__ = 'game_sessions'
	characters = relation('SessionCharacter', backref = 'game_session')

	def get_master (self):
		return SessionCharacter.query.filter_by(game_session_id = self.id, user_role = "master").first()

class SessionCharacter (Model):
	__tablename__ = 'session_characters'
	user = relation('User')
	items_query = relation('SessionItem', lazy = 'dynamic')

	# JSON fields format
	# 1. skills
	# {skill1_id: '3 * level', skill2_id: '-15', skill3_id: skill2_name}
	# attrs of an item: {is_equipped, durability...} # TODO
	# 2. skill_points
	# {category1_id: 3, category_points2: 0}

	def as_dict (self, with_items = False):
		items = self.get_items() if with_items else {}
		return {
			'id': self.id,
			'name': self.name,
			'level': self.level,
			'xp': self.xp,
			'skills': self.get_skills(),
			'skill_points': self.skill_points,
			'items': items,
			'avatar': self.user.get_gravatar_link(size = 40),
		}

	def get_skills (self):
		skills_dict = {}

		# Base
		for skill_id in self.skills.keys():
			base_value = self.skills[skill_id]
			skill_id = int(skill_id)
			skills_dict[skill_id] = {
				'base_value': base_value,
				'effective_value': self.get_skill_effective_value(skill_id),
			}

		# Add the character's race
		if self.race_id:
			race = Race.query.get(self.race_id)
			for skill_id, skill_val in race.skills.viewitems():
				skill_id = int(skill_id)
				skills_dict.setdefault(skill_id, {'effective_value': 0, 'base_value': 0})
				skills_dict[skill_id]['effective_value'] += skill_val

		# Add the character's class
		if self.class_id:
			char_class = CharacterClass.query.get(self.class_id)
			if char_class.skills:
				for skill_id, skill_val in char_class.skills.viewitems():
					skill_id = int(skill_id)
					skills_dict.setdefault(skill_id, {'effective_value': 0, 'base_value': 0})
					skills_dict[skill_id]['effective_value'] += skill_val

		# Worn items
		worn_session_items_query = self.items_query.filter(SessionItem.attrs['is_equippable'].cast(Boolean) == True).options(joinedload('item'))
		for session_item in worn_session_items_query:
			item_group_id_sq = DBSession.query(Item.group_id).filter_by(id = session_item.item_id).subquery()
			item_group = ItemGroup.query.filter_by(id = item_group_id_sq, is_equippable = True).first()
			if not item_group:
				continue

			item = session_item.item
			for skill_id, skill_val in item.skills.viewitems():
				skill_id = int(skill_id)
				skills_dict.setdefault(skill_id, {'effective_value': 0, 'base_value': 0})
				skills_dict[skill_id]['effective_value'] += skill_val

		# TODO: Used items

		return skills_dict

	def get_items (self):
		items = {'equipped': {}, 'inventory': {}}
		for session_item in self.items_query.options(joinedload('item')):
			item = session_item.item

			if session_item.attrs.get('is_equipped'):
				_key = 'equipped'
			else:
				_key = 'inventory'

			items[_key].setdefault(item.group_id, [])
			items[_key][item.group_id].append({
				'id': session_item.id,
				'title': item.title,
			})

		return items

	def get_skill_value (self, skill_id):
		character_skill = self.skills_query.filter_by(skill_id = skill_id).first()
		return character_skill.get_effective_value()

	def get_skill_by_title (self, skill_title):
		# TODO: avoid usage of this func by denormalization?
		skill = DBSession.query(Skill.id).filter_by(title = skill_title).first()
		if not skill:
			# TODO
			raise
		return skill

	def get_skill_effective_value (self, skill_id):
		skill_obj = Skill.query.get(skill_id)
		skill_formula = skill_obj.formula.strip()
		if skill_formula:
			evaluator = formula.SkillFormulaEvaluator(skill_obj, skill_formula, self)
			return evaluator.evaluate()
		return self.skills[str(skill_id)]

	def gain_xp (self, xp):
		rules = self.game_session.rules

		sum_xp = self.xp + xp
		new_level = rules.get_level(sum_xp)
		if new_level is None:
			# TODO: log error
			return

		self.xp = sum_xp

		# Level up?
		level_diff = new_level - self.level
		for i in range(0, level_diff):
			level_info = rules.get_level_info(self.level + 1)
			if not level_info:
				break # TODO: WTF?
			self.level += 1

			# inc skills
			for cat_id, _formula in level_info.get('skills_categories_formulas', {}).iteritems():
				self.skill_points.setdefault(cat_id, 0)
				points_gained = formula.FormulaEvaluator({}, _formula, self).evaluate()
				self.skill_points[cat_id] += points_gained

			flag_modified(self, 'skill_points')

		self.add()

class CharacterClass (Model):
	__tablename__ = 'character_classes'
	game_rules = relation('GameRules', backref = 'classes')

	def as_dict (self):
		return {
			'id': self.id,
			'rules_id': self.rules_id,
			'title': self.title,
			'skills': self.skills,
			'is_disables': self.is_disabled
		}

class PlayObject (Model):
	__tablename__ = 'game_session_playfield_objects'
	game_session = relation('GameSession', backref = 'play_objects')

	def as_dict (self, static_path):
		type_string = constants.PlayfieldObject.NAME_TO_TYPE.inv[self.type]

		data = {
			'id': self.id,
			'type_string': type_string,
			'x': self.x,
			'y': self.y,
		}

		if self.type == constants.PlayfieldObject.PLAYER:
			player_id = self.attrs['player_id']
			player = SessionCharacter.query.get(player_id) # TODO: Error?
			data['title'] = player.name
			data['img_url'] = player.user.get_gravatar_link(size = 40)
			data['player_id'] = player_id
		elif self.type == constants.PlayfieldObject.NPC:
			defaults = constants.PlayfieldObject.get_defaults(static_path)[type_string]

			data['title'] = self.title
			data['img_url'] = defaults['img_url']
		elif self.type == constants.PlayfieldObject.ITEM:
			defaults = constants.PlayfieldObject.get_defaults(static_path)[type_string]

			item_id = self.attrs['item']
			session_item = SessionItem.query.get(item_id) # TODO: Error?
			item = session_item.item
			data['title'] = item.title
			data['img_url'] = defaults['img_url']
			data['item_id'] = self.attrs['item']
			data['durability'] = session_item.attrs.get('durability', 0)

		return data

class Dice (Model):
	__tablename__ = 'dices'

	def get_image_url (self, static_path):
		return os.path.join(static_path, self.img_32)

	def as_dict (self, static_path):
		return {
			'id': self.id,
			'name': self.name,
			'num_of_sides': self.num_of_sides,
			'start_num': self.start_num,
			'max_value': self.max_value,
			'step': self.step,
			'image_url': self.get_image_url(static_path)
		}

	@property
	def max_value (self):
		return self.start_num + self.step * (self.num_of_sides - 1)

	def roll(self):
		return random.randint(0, self.num_of_sides - 1) * self.step + self.start_num

class RulesDice (Model):
	__tablename__ = 'game_rules__dices'
	game_rules = relation('GameRules')
	dice = relation('Dice')
