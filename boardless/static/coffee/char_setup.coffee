class window.SkillControl
	constructor: (@freeSkillPoints, @pointsToSpent) ->
		@do_binds()

	changeSkill: (idx, skill_id, modif) =>
		curr_val = parseInt $("#skill-#{skill_id}").text(), 10
		cat_id = $("#skill-#{skill_id}").data "categoryId"
		new_val = curr_val  + modif

		if new_val < 0 or @freeSkillPoints[cat_id] < (@pointsToSpent[cat_id] - modif) or (@pointsToSpent[cat_id] - modif) < 0
			return

		@pointsToSpent[cat_id] -= modif
		$("#input-#{skill_id}-mod").val new_val
		$("#skill-#{skill_id}").text new_val
		$("#category-points-#{cat_id}").text @pointsToSpent[cat_id]

	do_binds: =>
		$('.js-skill-dec').bind "click", (e) =>
			$elem = $(e.currentTarget)
			db_id = $elem.data "dbId"
			skill_id = $elem.data "skillId"
			@changeSkill(db_id, skill_id, -1)

		$('.js-skill-inc').bind "click", (e) =>
			$elem = $(e.currentTarget)
			db_id = $elem.data "dbId"
			skill_id = $elem.data "skillId"
			@changeSkill(db_id, skill_id, 1)
