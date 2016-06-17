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
<%block name="title"> View rules ${rules.title} </%block>
<article class="main-block">
	<div class="wrapper">
		<p class="navigation">
			<a href="${request.route_url('games.list')}">Home</a> <span>View rules</span>
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
				## Base
				## Form tag here is just for markup
				<form>
					<div class="form-title w100">Base settings</div>
					<div class="w70">
						<div class="w75 p-default">
							${defs.field_with_errors(form.title, disabled = "disabled")}
						</div>
						<div class="w50 p-default">
							${defs.field_with_errors(form.max_players, disabled = "disabled")}
						</div>
					</div>

					<hr />

					## Dices
					<div class="form-title w100">Dices</div>
					<div class="row clear">
						<div class="column w100 p-default">
							<ul class="dices">
								% for dice in rules.dices:
									<li>
										<label for="dice_${dice.name}" class="text-center no-border">
											<img src="/static/${dice.img_128}" />
											<span class="w100"><strong>${dice.name}</strong></span>
										</label>
									</li>
								% endfor
							</ul>
						</div>
					</div>
				</form>
			</div>
			<div id="skills">
				<table class="skills-table">
					% for skills_category in rules.skills_categories_query.filter_by(is_disabled = False).order_by('priority'):
						<tr class="skills-category" data-skills_category_id="${skills_category.id}">
							<td colspan="3">Category <span class="title">${skills_category.title}</span>:</td>
						</tr>
						
						<% category_skills = rules.get_child_query_by_priority('skills').filter_by(category_id = skills_category.id).filter_by(is_disabled = False).order_by('priority').all() %>
						
						%if category_skills:
							% for query_tpl in category_skills:
								<tr data-child_type="skill" class="skill" data-child_id="${query_tpl.Skill.id}" data-is_disabled="${1 if query_tpl.Skill.is_disabled else 0}" data-skills_category_id="${skills_category.id}">
									<td class="js-skill-title js-child-title ${'child-title-disabled' if query_tpl.Skill.is_disabled else ''}">${query_tpl.Skill.title}</td>
									<td>Base value: ${query_tpl.Skill.base_value} / Max value: ${query_tpl.Skill.max_value}</td>
									<td></td>
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
					<% no_category_skills = rules.get_child_query_by_priority('skills').filter_by(category_id = None).filter_by(is_disabled = False).all() %>
					% if no_category_skills:
						% for query_tpl in no_category_skills:
							<tr class="skill" data-child_type="skill" data-child_id="${query_tpl.Skill.id}" data-is_disabled="${int(query_tpl.Skill.is_disabled)}"data-skills_category_id="none">
								<td class="js-skill-title js-child-title ${'child-title-disabled' if query_tpl.Skill.is_disabled else ''}">${query_tpl.Skill.title}</td>
								<td>Base value: ${query_tpl.Skill.base_value} / Max value: ${query_tpl.Skill.max_value}</td>
								<td></td>
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
			<table class="races-table">
				% for query_tpl in rules.get_child_query_by_priority('races').filter_by(is_disabled = False):
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
						<td></td>
					</tr>
				% endfor
			</table>
		</div>

		## Classes
		<div id="classes">
			<div class="table-block w100 p-default">
				<table class="character-classes-table">
					% for query_tpl in rules.get_child_query_by_priority('character_class').filter_by(is_disabled = False):
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
						<td></td>
					</tr>
					% endfor
				</table>
			</div>
		</div>

		## XP
		<div id="xp">
			<div class="table-block w100 p-default">
				<p class="block-title">XP</p>
					<table id='character-levels-table'>
						<tr class="js-head">
							<th>Level</th>
							<th>XP</th>
							% for skills_category in rules.skills_categories_query.order_by('priority').filter_by(is_disabled = False):
								<th> Granted skills formula (${skills_category.title})</th>
							% endfor
						</tr>
						% for settings in rules.level_settings:
							<tr class="js-level-row">
								<td class="level_settings-level">
									${settings['level']}
								</td>
								<td>
									<input value="${settings['xp']}" readonly="readonly" />
								</td>
								% for num, skills_category in enumerate(rules.skills_categories_query.order_by('priority').filter_by(is_disabled = False)):
									<td>
										<input value="${settings.get('skills_categories_formulas',{}).get(str(skills_category.id), 0)}" readonly="readonly" />
									</td>
								% endfor
							</tr>
						% endfor
					</table>
			</div>
		</div>

		<div id="items">
			<table class="items-table" id="items_table">
				% for ig in rules.item_groups_query.order_by('priority').filter_by(is_disabled = False):
					<tr class="item-group" data-item_group_id="${ig.id}" data-child_type="items_group">
						<td>
							Group <span class="title">${ig.title}</span>
						</td>
						<td colspan="4">
							<button type="button" class="btn btn-xs ${'btn-green' if ig.is_equippable else 'btn-grey'}"> Is equippable</button>
							<button class="btn btn-xs btn-${'green' if ig.is_usable else 'grey'}">Is usable</button>
							<button class="btn btn-xs btn-${'green' if ig.has_charge else 'grey'}">Has charge</button>
							<button class="btn btn-xs btn-${'green' if ig.has_durability else 'grey'}">Has durability</button>
							<button class="btn btn-xs btn-${'green' if ig.has_damage else 'grey'}">Has damage</button>
						</td>
					</tr>

					% for i, item in enumerate(ig.items_query.order_by('priority').filter_by(is_disabled = False)):
						<tr class="item" data-items_group_id="${item.group_id}" data-child_type="item" data-child_id="${item.id}" data-is_disabled="${int(item.is_disabled)}">
							<td>${i + 1}</td>
							<td class="js-child-title ${'child-title-disabled' if item.is_disabled else ''}">${item.title}</td>
							<td>Slots Consumed: ${item.attrs['slots_consumed']}</td>
							<td>
								${u', '.join(u'{0}: {1}'.format(skills_cache[int(skill_id)], h.numeric_with_sign(mod)) for skill_id, mod in item.skills.viewitems())}
							</td>
							<td>
							</td>
						</tr>
					%endfor 
				% endfor
			</table>
			</div>
		</div>
			</div>
		</section>
		</div>
	</div>
</article>