class window.RulesEdit
	constructor: (@rules_id, skills) ->
		# add_class = new board.AddCharacterFeature skills, document.getElementById('table-classes-list'), 'class_skill_id'
		# add_race = new board.AddCharacterFeature skills, document.getElementById('table-races-list'), 'race_skill_id'
		# add_perk = new board.AddCharacterFeature skills, document.getElementById('table-perks-list'), 'race_skill_id'

		do @do_binds
		return

	do_binds: =>
		$('.js-toggle-item_group-attr').bind 'click', (e) =>
			e.preventDefault()

			item_group_id = $(e.currentTarget).data 'itemGroupId'
			attr_name = $(e.currentTarget).data 'attrName'

			$.post '/api/rules/item_group/toggle_attribute',
				{
					rules_id: @rules_id,
					item_group: item_group_id,
					attr_name: attr_name,
				},
				( (response) -> 
					if response.success
						$(e.currentTarget).toggleClass 'btn-grey'
						$(e.currentTarget).toggleClass 'btn-green'
				),
			'json'

		$('.js-child-change-status-btn').bind 'click', (e) =>
			e.preventDefault()

			$parent = $(e.currentTarget).parent().parent()
			child_id = $parent.data 'child-id'
			child_type = $parent.data 'child-type'
			is_disabled = parseInt ($parent.data 'is-disabled')

			$.post '/api/rules/child/change_status/',
				{
					id: child_id,
					disable: not is_disabled,
					child_type: child_type,

				},
				( (response) -> 
					if response.success
						$btn = $parent.find '.js-child-change-status-btn:first'

						switch child_type
							when "item"
								if is_disabled
									$btn.removeClass 'btn-grey'
									$btn.addClass 'btn-green'
									$btn.removeClass 'icon-add'
									$btn.addClass 'icon-added'
									$parent.data('is-disabled', 0)
								else
									$btn.removeClass 'btn-green'
									$btn.addClass 'btn-grey'
									$btn.removeClass 'icon-added'
									$btn.addClass 'icon-add'
									$parent.data('is-disabled', 1)
							else
								if is_disabled
									$btn.html 'Disable'
									$parent.data('is-disabled', 0)
								else
									$btn.html 'Enable'
									$parent.data('is-disabled', 1)
				),
			'json'

class LevelSettings
	constructor: (@rules_id, @level, @xp, @skills_categories_formulas, @perks_formula, @skills_categories) ->
		@formula_elem_ids = {'perks': "level_settings-#{@level}-perks_formula", 'skills_categories': {}}
		for skills_category in @skills_categories
			@formula_elem_ids.skills_categories[skills_category.id] = "level_settings-#{@level}-skills_category-#{skills_category.id}-formula"

class window.LevelEditor
	constructor: (@rules_id, @base_elem_id, level_settings_list, @skills_categories) ->
		@level_settings = []
		for ls in level_settings_list
			@level_settings.push new LevelSettings @rules_id, ls.level, ls.xp, ls.skills_categories_formulas, ls.perks_formula, @skills_categories

		@level_settings.sort((settings1, settings2) -> if settings1.level > settings2.level then 1 else if settings1.level == settings2.level then 0 else -1)
		@render_table()

		$('#level-table-add-rows').bind 'click', (e) =>
			$last_inserted_row = $('#character-levels-table tr:last')
			rows_to_ins = parseInt($('#level-rows-to-add').val())
			@add_lvl_rows rows_to_ins, $last_inserted_row

		@init_formula_editors_for_settings @level_settings

	add_lvl_rows: (rows_to_ins, $last_inserted_row) =>
		last_level = parseInt($last_inserted_row.find('.level_settings-level').text())
		last_level = 0 if isNaN(last_level)
		from_level = last_level + 1
		to_level = last_level + rows_to_ins

		perks_formula = $last_inserted_row.find("[name=level_settings-#{last_level - 1}-perks_formula]").val() or 0
		skills_categories_formulas = {}
		for num, skills_category of @skills_categories
			skills_categories_formulas[skills_category.id] = $last_inserted_row.find("[name=skills_categories_formulas-#{num}-formula]").val() or 0

		level_settings = []
		for level in [from_level..to_level]
			level_settings.push new LevelSettings @rules_id, level, '', skills_categories_formulas, perks_formula, @skills_categories

		rows_html = board.ECT.render '/static/js/templates/rules/character_level_rows.ect', {level_settings: level_settings, skills_categories: @skills_categories}
		$('#character-levels-table > tbody').append(rows_html)

		@init_formula_editors_for_settings level_settings

	init_formula_editors_for_settings: (level_settings) ->
		editor_objs = []
		for settings in level_settings
			editor_objs.push new board.FormulaEditor settings.formula_elem_ids.perks
			for category_id, elem_id of settings.formula_elem_ids.skills_categories
				editor_objs.push new board.FormulaEditor elem_id

		$('.js-skill-title').each ->
			# TODO: add only category skills to category formula editor
			for editor in editor_objs
				editor.add_keyword $(@).text()

	render_table: =>
		html = board.ECT.render '/static/js/templates/rules/character_level.ect', {level_settings: @level_settings, skills_categories: @skills_categories}
		$("##{ @base_elem_id }").html html
