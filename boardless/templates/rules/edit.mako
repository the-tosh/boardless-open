<%inherit file="boardless:templates/base.mako"/>
<%namespace name="defs" file="boardless:templates/defs.mako"/>
<%block name="styles">
	<link href="${request.static_url('boardless:static/css/tabs.css')}" rel="stylesheet" />
</%block>
<%block name="scripts">
	<script type="text/javascript">
		$(function() {
			window.page = new RulesPage(
			                            ${rules.id},
			                            ${[cat.as_dict() for cat in rules.skills_categories_query.order_by('priority')] | jsonify, n},
			                            ${{skill.id: skill.as_dict() for skill in rules.skills_query.order_by('priority')} | jsonify, n}
			)
			var skills_formula_editor = new board.FormulaEditor('skills-formula');
			$('.js-skill-title').each(function(){
				skills_formula_editor.add_keyword($(this).text());
			});
			// var level_editor = new LevelEditor(${rules.id}, 'character-level', ${rules.level_settings | jsonify, n}, ${[cat.as_dict() for cat in rules.skills_categories_query.order_by('priority').filter_by(is_disabled = False)] | jsonify, n});
			
			$('.tabgroup > div').hide();
			$('.tabgroup > div:first-of-type').show();

			$('.tabs a').click(function(e){
				e.preventDefault();
				var $this = $(this),
					tabgroup = '#'+$this.parents('.tabs').data('tabgroup'),
					others = $this.closest('li').siblings().children('a'),
					target = $this.attr('href');
				others.removeClass('active');
				$this.addClass('active');
				$(tabgroup).children('div').hide();
				$(target).show();
			})
		});
	</script>
	

</%block>
<%block name="title"> Edit rules ${rules.title} </%block>
<article class="main-block">
	<div class="wrapper">
		<p class="navigation">
			<a href="${request.route_url('games.list')}">Home</a> <span>Edit rules</span>
		</p>

		<ul class="tabs clearfix" data-tabgroup="first-tab-group">
			<li><a href="#main" class="active">Main</a></li>
			<li><a href="#skills">Skills</a></li>
			<li><a href="#races">Races</a></li>
			<li><a href="#classes">Classes</a></li>
			<li><a href="#xp">XP</a></li>
			<li><a href="#items">Items</a></li>
		</ul>

		<section id="first-tab-group" class="tabgroup rules-tabgroup">
			<div id="main">
				<form action="${request.route_url('rules.edit', rules_id = rules.id)}" name="edit_main" method="POST">
					## Base
					<div class="form-title w100">Base settings</div>
					<div class="w70">
						<div class="w75 p-default">
							${defs.field_with_errors(form.title)}
						</div>
						<div class="w50 p-default">
							${defs.field_with_errors(form.max_players)}
						</div>
					</div>

					<hr />

					## Dices
					<div class="form-title w100">Dices</div>
					<div class="row clear">
						<div class="column w100 p-default">
							<ul class="dices">
								% for dice in base_dice.query.all():
									<li>
										<input type="checkbox" id="dice_${dice.name}" ${'checked' if dice in rules.dices else ''} name="dices" value="${dice.id}">
										<label for="dice_${dice.name}" class="text-center">
											<img src="/static/${dice.img_128}" />
											<span class="w100"><strong>${dice.name}</strong></span>
										</label>
									</li>
								% endfor
							</ul>
						</div>
					</div>
					<div class="row clear">
						<div class="column w15">
							<button type="submit" class="btn btn-blue">Apply changes</button>
						</div>

						<div class="column w85 text-right">
							<button type="button" id="js-finalize-btn" class="btn btn-red">Finalize</button>
						</div>
					</div>
				</form>
			</div>
			<div id="skills">
				<div class="row text-right">
					<div class="column w100">
						<button type="button" class="btn btn-blue" data-target="skills" data-state="close" data-opened-text="Close" data-closed-text="Add skill" onclick="page.toggle_form(this);">Add skill</button>
					</div>
				</div>
				<div class="row js-skill-forms" style="display:none;">
					<div class="column w70">
						<form action="/api/rules/skill/create" name="add_skill" data-submit_type="ajax" data-reset-on-success="true">
							<div class="form-title w100">New skill</div>
							<div class="w100 p-default form-control">
								${defs.field_with_errors(skill_form.title)}
							</div>
							<div class="w100 p-default form-control">
								${defs.field_with_errors(skill_form.category)}
							</div>
							<div class="row clear">
								<div class=" column w50 p-default form-control">
									${defs.field_with_errors(skill_form.base_value)}
								</div>
								<div class=" column w50 p-default form-control">
									${defs.field_with_errors(skill_form.max_value)}
								</div>
							</div>
							<div class="w100 p-default form-control">
								${defs.field_with_errors(skill_form.formula)}
							</div>
							<div class="w100 form-control center">
								<button class="btn btn-blue">Create</button>
							</div>
						</form>
					</div>
					<div class="column w30">
						<form action="/api/rules/skills_category/create" name="add_skills_category" data-submit_type="ajax" data-reset-on-success="true">
							<div class="form-title w100">New skills category</div>
							<div class="w100 p-default form-control">
								${defs.field_with_errors(skill_category_form.title)}
							</div>
							<div class="w100 p-default form-control">
								${defs.field_with_errors(skill_category_form.base_value)}
							</div>
							<div class="w100 form-control center" >
								<button class="btn btn-blue" type="submit">Create</button>
							</div>
						</form>
						
					</div>
				</div>
				<table class="skills-table">
					% for skills_category in rules.skills_categories_query.order_by('priority'):
						<tr class="skills-category" data-skills_category_id="${skills_category.id}">
							<td colspan="3">Category <span class="title">${skills_category.title}</span>:</td>
						</tr>
						
						<% category_skills = rules.get_child_query_by_priority('skills').filter_by(category_id = skills_category.id).order_by('priority').all() %>
						
						%if category_skills:
							% for query_tpl in category_skills:
								<tr data-child_type="skill" class="skill" data-child_id="${query_tpl.Skill.id}" data-is_disabled="${1 if query_tpl.Skill.is_disabled else 0}" data-skills_category_id="${skills_category.id}">
									<td class="js-skill-title js-child-title ${'child-title-disabled' if query_tpl.Skill.is_disabled else ''}">${query_tpl.Skill.title}</td>
									<td>Base value: ${query_tpl.Skill.base_value} / Max value: ${query_tpl.Skill.max_value}</td>
									<td>
										<button class="btn btn-${'blue' if query_tpl.Skill.is_disabled else 'red'} btn-xs" type="button" onclick="page.change_status(this);">${"Enable" if query_tpl.Skill.is_disabled else "Disable"}</button>
									</td>
								</tr>
							% endfor
						
						%else:
							<tr class="category-no-skills" data-skills_category_id="${skills_category.id}">
								<td colspan="3">No skills</td>
							</tr>
						% endif
					% endfor
					
					<tr class="skills-category" data-skills_category_id="none">
						<td colspan="3"><span class="title">No category</span></td>
					</tr>
					<% no_category_skills = rules.get_child_query_by_priority('skills').filter_by(category_id = None).all() %>
					% if no_category_skills:
						% for query_tpl in no_category_skills:
							<tr class="skill" data-child_type="skill" data-child_id="${query_tpl.Skill.id}" data-is_disabled="${int(query_tpl.Skill.is_disabled)}"data-skills_category_id="none">
								<td class="js-skill-title js-child-title ${'child-title-disabled' if query_tpl.Skill.is_disabled else ''}">${query_tpl.Skill.title}</td>
								<td>Base value: ${query_tpl.Skill.base_value} / Max value: ${query_tpl.Skill.max_value}</td>
								<td>
									<button class="btn btn-${'blue' if query_tpl.Skill.is_disabled else 'red'} btn-xs" type="button" onclick="page.change_status(this);">${"Enable" if query_tpl.Skill.is_disabled else "Disable"}</button>
								</td>
							</tr>
						% endfor
					%else:
						<tr class="category-no-skills" data-skills_category_id="none">
								<td colspan="3">No skills</td>
							</tr>
					%endif
				</table>
			</div>

		## Races
		<div id="races">
			<div class="row text-right">
				<div class="column w100">
					<button type="button" class="btn btn-blue" data-target="races" data-state="close" data-opened-text="Close" data-closed-text="Add race" onclick="page.toggle_form(this);">Add race</button>
				</div>
			</div>

			<div class="row js-race-form" style="display:none;">
				<form action="/api/rules/race/create" name="add_race" data-submit_type="ajax" data-reset-on-success="true">
					<div class="w100">
						<div class="w50 p-default">
							${defs.field_with_errors(race_form.title)}
						</div>
					</div>
					<div class="w100 js-race-skills"></div>

					<div class="w100 p-default form-control">
						<button type="button" class="btn btn-blue" data-target=".js-race-skills" onclick="page.add_skill_to_obj('race', this);">Add Skill</button>
					</div>

					<div class="w100 p-default form-control">
						## <a href="" class="btn btn-blue">Save</a>
						<button class="btn btn-blue" type="submit"> Create </button>
						## <a href="" class="btn btn-blue">Cancel</a>
					</div>
				</form>
			</div>
			<table class="races-table">
				% for query_tpl in rules.get_child_query_by_priority('races'):
					<tr data-child_type="race" data-child_id="${query_tpl.Race.id}" data-is_disabled="${int(query_tpl.Race.is_disabled)}">
						<td>${query_tpl._priority}</td>
						<td class="js-child-title ${'child-title-disabled' if query_tpl.Race.is_disabled else ''}">${query_tpl.Race.title}</td>
						<td>
							% if query_tpl.Race.skills:
								${u', '.join(u'{0}: {1}'.format(skills_cache[int(skill_id)], h.numeric_with_sign(mod)) for skill_id, mod in query_tpl.Race.skills.viewitems())}
							% else:
								NO STATS
							% endif
						</td>
						<td>
							<button class="btn btn-${'blue' if query_tpl.Race.is_disabled else 'red'} btn-xs" type="button" onclick="page.change_status(this);">${"Enable" if query_tpl.Race.is_disabled else "Disable"}</button>
						</td>
					</tr>
				% endfor
			</table>
		</div>

		## Classes
		<div id="classes">
			<div class="row text-right">
				<div class="column w100">
					<button type="button" class="btn btn-blue" data-target="classes" data-state="close" data-opened-text="Close" data-closed-text="Add Class" onclick="page.toggle_form(this);">Add Class</button>
				</div>
			</div>

			<div class="row js-class-form" style="display:none;">
				<form action="/api/rules/class/create" name="add_class" data-submit_type="ajax" data-reset-on-success="true">
					<div class="w100">
						<div class="w50 p-default">
							${defs.field_with_errors(class_form.title)}
						</div>
					</div>
					<div class="w100 js-character-class-skills"></div>

					<div class="w100 p-default form-control">
						<button type="button" class="btn btn-blue" data-target=".js-character-class-skills" onclick="page.add_skill_to_obj('class', this);"> Add Skill</button>
					</div>

					<div class="w100 p-default form-control">
						<button class="btn btn-blue" type="submit"> Create </button>
					</div>
				</form>
			</div>
			<div class="table-block w100 p-default">
				<table class="character-classes-table">
					% for query_tpl in rules.get_child_query_by_priority('character_class'):
					<tr data-child_type="character_class" data-child_id="${query_tpl.CharacterClass.id}" data-is_disabled="${int(query_tpl.CharacterClass.is_disabled)}">
						<td>${query_tpl._priority}</td>
						<td class="js-child-title ${'child-title-disabled' if query_tpl.CharacterClass.is_disabled else ''}">${query_tpl.CharacterClass.title}</td>
						<td>
							% if query_tpl.CharacterClass.skills:
								${u', '.join(u'{0}: {1}'.format(skills_cache[int(skill_id)], h.numeric_with_sign(mod)) for skill_id, mod in query_tpl.CharacterClass.skills.viewitems())}
							% else:
								NO STATS
							% endif
						</td>
						<td>
							<button class="btn btn-${'blue' if query_tpl.CharacterClass.is_disabled else 'red'} btn-xs" type="button" onclick="page.change_status(this);">${"Enable" if query_tpl.CharacterClass.is_disabled else "Disable"}</button>
						</td>
					</tr>
					% endfor
					## <tr class="new-table-item">
					## 	<td colspan="4">
					## 		<p class="new-table-item-title w100 p-default"><a href="" class="opener-btn">Add class</a></p>
					## 		<form class="hidden validate-form" data-form-url="/api/rules/class/create" data-form-success-text="Class has been saved" data-form-callback="add_hash">
					## 				<input type="hidden" name="rules_id" value="${rules.id}" />
					## 				<div class="w100">
					## 					<div class="w50 p-default">
					## 						${defs.field_with_errors(class_form.title)}
					## 					</div>
					## 				</div>
					## 				% if rules.skills_query.count():
					## 					<div class="w100">
					## 						<div class="w50 p-default">
					## 							<label for='class_skill_id_0'>Skill name</label>
					## 							<select name="skills-0-skill_id" id="class_skill_id_0">
					## 								<option value="IGNORE-THIS-FIELD" value="false">Select skill</option>
					## 								% for skill in rules.skills_query.order_by('category_id', 'priority'):
					## 									<option value="${skill.id}" data-values-range="${skill.base_value} ${skill.max_value}">${skill.title}</option>
					## 								% endfor
					## 							</select>
					## 						</div>
					## 					</div>

					## 					<div class="w50 p-default clear-left">
					## 						<a href="" class="add-skill-block">Add a skill</a>
					## 					</div>
					## 				% endif

					## 				<div class="w100 p-default">
					## 					<a href="" class="btn btn-blue">Save</a>
					## 					<a href="" class="btn btn-blue cansel-btn">Cancel</a>
					## 				</div>
					## 			</div>
					## 		</form>
					## 	</td>
					## </tr>
				</table>
			</div>
		</div>

		## Dices
		<div id="dices">
			<div class="table-block w100 p-default">
				<p class="block-title">Dices</p>
				<form class="validate-form" data-form-url="/api/rules/dices/choose" data-form-success-text="Dices have been saved" data-form-callback="add_hash">
					<input type="hidden" name="rules_id" value="${rules.id}" />
					<select multiple="multiple" id="dice-select" name="dice_id">
					% for dice in base_dice.query.all():
						<option value="${dice.id}" ${'selected="selected"' if dice in rules.dices else ''}>Sides: ${dice.num_of_sides} Start value: ${dice.start_num} Step: ${dice.step}</option>
					% endfor
					</select>
					<div class="w100 p-default">
						<a href="" class="btn btn-blue ">Save</a>
					</div>
				</form>
			</div>
		</div>

		## XP
		<div id="xp">
			<div class="table-block w100 p-default">
				<p class="block-title">XP</p>
					<form action="/api/rules/character_levels" name="character_levels" data-submit_type="ajax" data-reset-on-success="false">
						<table id='character-levels-table'>
							<tr class="js-head">
								<th>Level</th>
								<th>XP</th>
								% for skills_category in rules.skills_categories_query.order_by('priority'):
									<th> Granted skills formula (${skills_category.title})</th>
								% endfor
							</tr>
							% for settings in rules.level_settings:
								<tr class="js-level-row">
									<td class="level_settings-level">
										${settings['level']}
									</td>
									<td>
										<input name="level_settings-${settings['level'] - 1}-rules_id" type="hidden" value="${rules.id}">
										<input name="level_settings-${settings['level'] - 1}-xp" type="text" value="${settings['xp']}" />
									</td>
									% for num, skills_category in enumerate(rules.skills_categories_query.order_by('priority')):
							## 			<%
							## 				formula = settings.skills_categories_formulas[skills_category.id] or 0
							## 				# TODO: Doublequotes in formula conflict with dublequotes in HTML markup. Sick!
							## 			%>

										<td>
											<input type="hidden" name="skills_categories_formulas-${num}-category_id" value="${skills_category.id}">
											<input type="hidden" name="skills_categories_formulas-${num}-level" value="${settings['level']}">

											<input id="${settings['level']}_${skills_category.id}" class="js-level-formula-field" name="skills_categories_formulas-${num}-formula" type="text" value="${settings.get('skills_categories_formulas',{}).get(str(skills_category.id), 0)}" />
										</td>
									% endfor
								</tr>
							% endfor
						</table>
					
					<div style="margin-top: 10px;">
						<button type="button"class="btn btn-blue" onclick="page.add_xp_rows();">Add rows</button> <input class="required" id="level-rows-to-add" value="3"/>
					</div>
					<button type="submit" class="btn btn-blue">Save</button>
					</form>
				## <form class="validate-form" data-form-url="/api/rules/character_levels" data-form-success-text="Levels have been saved" data-form-callback="add_hash">
				## 	<input type="hidden" name="rules_id" value="${rules.id}" />
				## 	<div id="character-level">
				## 	</div>
				## 	<div class="w100 p-default">
				## 		<a href="" class="btn btn-blue ">Save</a>
				## 	</div>
				## </form>
			</div>
		</div>

		<div id="items">
			<div class="row">
				<div class="column w10">
					<button type="button" class="btn btn-blue" data-target="items" data-state="close" data-opened-text="Close" data-closed-text="Add Item" onclick="page.toggle_form(this);">Add Item</button>
				</div>
			</div>
			<div class="row js-item-form" style="display:none;">
				<div class="column w50">
					<form action="/api/rules/item/create" name="add_item" data-submit_type="ajax" data-reset-on-success="true">
						<div class="form-title w100">New item</div>
						<div class="w100 p-default form-control">
							${defs.field_with_errors(item_form.title)}
						</div>
						<div class="w100 p-default form-control">
							${defs.field_with_errors(item_form.group_id)}
						</div>
						<div class="w100 p-default form-control">
							${defs.field_with_errors(item_form.slots_consumed)}
						</div>
						<div class="w100 js-item-skills">
						
						</div>
						<div class="w100 p-default form-control">
							<button type="button" class="btn btn-blue" data-target=".js-item-skills" onclick="page.add_skill_to_obj('item', this);"> Add Skill</button>
						</div>
						<div class="w100 form-control center" >
							<button class="btn btn-blue" type="submit">Create</button>
						</div>
					</form>
					
				</div>
				<div class="column w50">
					<form action="/api/rules/item_group/create" name="add_items_group" data-submit_type="ajax" data-reset-on-success="true">
						<div class="form-title w100">New item group</div>
						<div class="w100 p-default form-control">
							${defs.field_with_errors(item_group_form.title)}
						</div>
						<div class="w100 p-default form-control">
							${defs.field_with_errors(item_group_form.max_worn_items)}
						</div>
						<div class="w50 p-default form-control">
							${defs.checkbox_with_errors(item_group_form.is_equippable)}
						</div>
						<div class="w50 p-default form-control">
							${defs.checkbox_with_errors(item_group_form.is_usable)}
						</div>
						<div class="w50 p-default form-control">
							${defs.checkbox_with_errors(item_group_form.has_charge)}
						</div>
						<div class="w50 p-default form-control">
							${defs.checkbox_with_errors(item_group_form.has_durability)}
						</div>
						<div class="w50 p-default form-control">
							${defs.checkbox_with_errors(item_group_form.has_damage)}
						</div>
						<div class="w100 form-control center" >
							<button class="btn btn-blue" type="submit">Create</button>
						</div>
					</form>
				</div>
			</div>
			<table class="items-table" id="items_table">
				% for ig in rules.item_groups_query.order_by('priority'):
					<tr class="item-group" data-item_group_id="${ig.id}" data-child_type="items_group">
						<td>
							Group <span class="title">${ig.title}</span>
						</td>
						<td colspan="4">
							<button type="button" class="btn btn-xs ${'btn-green' if ig.is_equippable else 'btn-grey'}" data-item-group-id="${ig.id}" data-attr-name="is_equippable" onclick="page.change_item_group_attr(this);"> Is equippable</button>
							<button class="btn btn-xs btn-${'green' if ig.is_usable else 'grey'}" data-item-group-id="${ig.id}" data-attr-name="is_usable" onclick="page.change_item_group_attr(this);">Is usable</button>
							<button class="btn btn-xs btn-${'green' if ig.has_charge else 'grey'}" data-item-group-id="${ig.id}" data-attr-name="has_charge" onclick="page.change_item_group_attr(this);">Has charge</button>
							<button class="btn btn-xs btn-${'green' if ig.has_durability else 'grey'}" data-item-group-id="${ig.id}" data-attr-name="has_durability" onclick="page.change_item_group_attr(this);">Has durability</button>
							<button class="btn btn-xs btn-${'green' if ig.has_damage else 'grey'}" data-item-group-id="${ig.id}" data-attr-name="has_damage" onclick="page.change_item_group_attr(this);" >Has damage</button>
						</td>
						## <td>
						## 	<button class="btn btn-xs btn-${'blue' if not ig.is_disabled else 'red'}" data-item-group-id="${ig.id}" data-attr-name="is_disabled">Enabled</button>
						## </td>
					</tr>

					% for i, item in enumerate(ig.items_query.order_by('priority')):
						<tr class="item" data-items_group_id="${item.group_id}" data-child_type="item" data-child_id="${item.id}" data-is_disabled="${int(item.is_disabled)}">
							<td>${i + 1}</td>
							<td class="js-child-title ${'child-title-disabled' if item.is_disabled else ''}">${item.title}</td>
							<td>Slots Consumed: ${item.attrs['slots_consumed']}</td>
							<td>
								${u', '.join(u'{0}: {1}'.format(skills_cache[int(skill_id)], h.numeric_with_sign(mod)) for skill_id, mod in item.skills.viewitems())}
							</td>
							<td>
								<button class="btn btn-${'red' if item.is_disabled else 'blue'} btn-xs" type="button" onclick="page.change_status(this);">${"Enable" if item.is_disabled else "Disable"}</button>
							</td>
						</tr>
					%endfor 
				% endfor
			</table>
			</div>
		</div>
			</div>
		</section>
################
		</div>

		## Items
		

		
	</div>
</article>