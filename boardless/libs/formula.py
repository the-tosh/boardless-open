# _*_ coding: utf-8 _*_

import ast

# from boardless import helpers as h

FORMULA_DEFAULT_KEYWORDS = ('level', 'self')

###################################################
# AST's visitors and transformers
###################################################

class VariablesCollectionVisitor (ast.NodeVisitor):
	def __init__ (self, dynamic_keywords):
		self.dynamic_keywords = dynamic_keywords
		self.VARIABLE_NAMES = []

	def visit_Name (self, node):
		# For backward compatibility
		name = node.id
		if name not in FORMULA_DEFAULT_KEYWORDS and name not in self.dynamic_keywords:
			self.VARIABLE_NAMES.append(name)

	def visit_Str (self, node):
		name = node.s
		if name not in FORMULA_DEFAULT_KEYWORDS and name not in self.dynamic_keywords:
			self.VARIABLE_NAMES.append(name)

class VarToValTransformer (ast.NodeTransformer):
	def __init__ (self, kwords, character, *args, **kwargs):
		self.character = character
		self.name2val = self._init_name2value_mapper(kwords)

		return super(VarToValTransformer, self).__init__(*args, **kwargs)

	def _init_name2value_mapper (self, kwords):
		kwords['level'] = self.character.level
		return kwords

	def _get_value_by_name (self, name):
		if name in self.name2val:
			return self.name2val[name]

		skill = self.character.get_skill_by_title(name) # TODO: Get effective value by name
		return self.character.get_skill_effective_value(skill.id)

	def visit_Name (self, node):
		# For backward compatibility
		value = self._get_value_by_name(node.id)
		return ast.copy_location(ast.Num(value), node)

	def visit_Str (self, node):
		value = self._get_value_by_name(node.s)
		return ast.copy_location(ast.Num(value), node)

###################################################
# Custom objects
###################################################
class FormulaEvaluator (object):
	def __init__ (self, kwords, formula, character):
		self.kwords = kwords
		self.formula = formula
		self.character = character

	def evaluate (self):
		mdl = ast.parse(self.formula, mode = 'eval')
		transformer = VarToValTransformer(self.kwords, self.character)
		expr = transformer.visit(mdl)

		return eval(compile(expr, '<string>', 'eval')) # TODO Validation

class SkillFormulaEvaluator (FormulaEvaluator):
	def __init__ (self, skill, formula, character):
		kwords = {
			skill.title: character.skills[str(skill.id)],
			'self': character.skills[str(skill.id)],
		}
		super(SkillFormulaEvaluator, self).__init__(kwords, formula, character)
