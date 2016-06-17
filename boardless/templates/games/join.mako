<%inherit file="boardless:templates/base.mako"/>
<%namespace name="defs" file="boardless:templates/defs.mako"/>

<%block name="scripts">
		<script type="text/javascript">
			var skill_ctrl;
			$(function() {
				skill_ctrl = new SkillControl(${free_skill_points | jsonify, n}, ${free_skill_points | jsonify, n});
			});
		</script>
</%block>

<%block name="title"> Join ${rules.title}</%block>

<form method="POST" action="${request.route_url('games.join', game_session_id = game_session.id)}">
	<div class="w70">
		<div class="w75 p-default">
			${defs.field_with_errors(form.name)}
		</div>
	</div>

	% if form.race.query.count():
		<div class="w70">
			<div class="w75 p-default">
				${defs.field_with_errors(form.race)}
			</div>
		</div>
	% endif

	% if form.cls.query.count():
		<div class="w70">
			<div class="w75 p-default">
				${defs.field_with_errors(form.cls)}
			</div>
		</div>
	% endif

	<div class="w70">
		<div class="w75 p-default">

			Skills

			<table class="choose-skills">
				<tr>
					<td>Title</td>
					<td>Base points number</td>
					<td>Added points</td>
				</tr>
				% for cat in rules.skills_categories_query:
					<tr>
						<td colspan="3"><strong>${cat.title}</strong> category (<span id="category-points-${cat.id}">${cat.base_value}</span> points left)</td>
					</tr>
					% for idx, skill in enumerate(skills_by_cat[cat.id]):
						<tr>
							<td>${skill.title}</td>
							<td>${skill.base_value}</td>
							% if skill.formula:
								<td>
									<span>0 (skill can not be changed)</span>
								</td>
							% else:
								<td>
									<span id="skill-${skill.id}" data-category-id="${cat.id}">0</span>&nbsp;<a style="text-decoration: none;" class="js-skill-inc" href="javascript:void(0)" data-db-id="${idx}" data-skill-id="${skill.id}">+</a>|<a style="text-decoration: none;" href="javascript:void(0)" class="js-skill-dec" data-db-id="${idx}" data-skill-id="${skill.id}">-</a>

									<input type="hidden" name="skills-${idx}-skill_id" value="${skill.id}"/>
									<input type="hidden" id="input-${skill.id}-mod" name="skills-${idx}-mod" value="0"/>
								</td>
							% endif
						</tr>
					% endfor
				% endfor
				% if None in skills_by_cat:
					<tr>
						<td colspan="3"><strong>No category</strong></td>
					</tr>
					% for skill in skills_by_cat[None]:
							<tr>
								<td>${skill.title}</td>
								<td>${skill.base_value}</td>
								<td>0</td>
							</tr>
					% endfor
				% endif
			</table>
		</div>
	</div>

	<div class="w100 p-default">
		<input type="submit" class="btn btn-blue" value="Save" />
	</div>
</form>
