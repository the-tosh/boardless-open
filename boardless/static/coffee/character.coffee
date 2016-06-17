class board.Skill
	constructor: ({@id, @title, @base_value, @max_value, @formula, @category_id, @related_skills}) ->

	get_char_elem: (character_id) =>
		$(".js-skill-value-#{character_id}[data-skill-id=#{@id}]:first .js-value")

class board.Master
	constructor: ->
		@changed_points = {}

		@init_globals()
		# @reset_data_to_apply()

	init_globals: =>
		board.SESSION_GLOBALS.MASTER = @

	reset_data_to_apply: =>
		for char_id, character of board.SESSION_GLOBALS.CHARACTERS
			@changed_points[character.id] = {}
			for skill_id, skill of board.SESSION_GLOBALS.SKILLS
				@changed_points[character.id][skill.category_id] = 0

	do_sheet_binds: ->
		$('.js-inc-points').bind 'click', (e) =>
			character_id = parseInt $(e.currentTarget).data 'characterId'
			category_id = parseInt $(e.currentTarget).data 'categoryId'
		#	@inc_points character_id, category_id

		$('.js-dec-points').bind 'click', (e) =>
			character_id = parseInt $(e.currentTarget).data 'characterId'
			category_id = parseInt $(e.currentTarget).data 'categoryId'
		#	@dec_points character_id, category_id

		$('#js-characters-sheet-apply-btn').bind 'click', (e) =>
			e.preventDefault()
			@apply()

	#inc_points: (character_id, category_id) =>
	#	$selector = $("#js-category-points-value-#{character_id}-#{category_id}")
	#	old_val = parseInt $selector.html()
	#	new_val = old_val + 1
	#	$selector.html new_val

	#	@changed_points[character_id][category_id] += 1

	#dec_points: (character_id, category_id) =>
	#	$selector = $("#js-category-points-value-#{character_id}-#{category_id}")
	#	old_val = parseInt $selector.html()
	#	new_val = old_val - 1
	#	$selector.html new_val

	#	@changed_points[character_id][category_id] -= 1

	apply: =>
		#@apply_category_points()
		@apply_xp()

	apply_xp: =>
		xp_data = {
			'game_session_id': board.SESSION_GLOBALS.GAME_SESSION_ID,
			'xp': []
		}

		$('.js-addxp-character').each (i, el) =>
			$xp_el = $(el)
			char_id = parseInt($xp_el.data 'character-id')
			char_xp = parseInt($xp_el.val())

			if not char_xp
				return

			xp_data["xp-#{i}-character_id"] = char_id
			xp_data["xp-#{i}-character_xp"] = char_xp

		clb = (result) =>
			if result.success
				console.log 'AddXp: OK'
				$('.js-addxp-character').val(0)
			else
				console.log 'AddXp: ERROR!', result
		board.SESSION_GLOBALS.WSCLIENT.request 'CharactersAddXp', xp_data, clb

	apply_category_points: =>
		data = {
			'game_session_id': board.SESSION_GLOBALS.GAME_SESSION_ID,
		}

		num = 0
		for char_id, points_data of @changed_points
			for category_id, value of points_data
				if value == 0
					continue

				char_id_key = "points-#{num}-character_id"
				cat_id_key = "points-#{num}-category_id"
				val_key = "points-#{num}-value"

				data[char_id_key] = char_id
				data[cat_id_key] = category_id
				data[val_key] = value

				num += 1

		clb = (result) =>
			if result.success
				@reset_data_to_apply()
			else
				console.log result.error
		board.SESSION_GLOBALS.WSCLIENT.request 'CharacterChangeCategoryPoints', data, clb

class board.Character
	constructor: ({ @id, @name, @level, @xp, @role, @skills, @skill_points, @avatar, @items }) ->
		@is_online = false

	join: =>
		@is_online = true

	disconnect: =>
		@is_online = false

	update_params: (params) =>
		for outer_key, outer_value of params
			switch outer_key
				# For {id: {...}} objects
				when "skills", "skill_points", "items", "item_groups"
					for inner_key, inner_value of outer_value
						inner_key = parseInt(inner_key)
						@[outer_key][inner_key] = inner_value
				else
					@[outer_key] = outer_value

class board.ThePlayer extends board.Character
	constructor: ({ @id, @name, @level, @xp, @role, @skills, @skill_points, @avatar, @items, @item_groups }) ->
		super({ @id, @name, @level, @xp, @role, @skills, @skill_points, @avatar, @items })

		@changed_skills = {}
		@changed_categories = {}
		@reset_data_to_apply()

		@init_globals()

		@render_dummy()
		@render_inventory()

	init_globals: =>
		board.SESSION_GLOBALS.THE_PLAYER = @

	reset_data_to_apply: =>
		for skill_id, skill_data of @skills
			@changed_skills[skill_id] = 0

		for category_id, category_data of @skill_points
			@changed_categories[category_id] = 0

	render_dummy: =>
		$tbl = $('#the-player-dummy-tbl')

		data = {
			'item_groups': @item_groups,
			'items': @items,
		}

		html = board.ECT.render '/static/js/templates/play/dummy.ect', data
		$tbl.html(html)

		$('.js-take-item-off').bind 'click', (e) =>
			item_id = $(e.currentTarget).data 'itemId'
			@take_item_off(item_id)

	render_inventory: =>
		$tbl = $('#the-player-inventory-tbl')

		data = {
			'item_groups': @item_groups,
			'items': @items,
		}

		html = board.ECT.render '/static/js/templates/play/inventory.ect', data
		$tbl.html(html)

		$('.js-put-item-on').bind 'click', (e) =>
			item_id = $(e.currentTarget).data 'itemId'
			@put_item_on(item_id)

	related_skills_prompt: (skill_id, new_value) =>
		related_skills = board.SESSION_GLOBALS.SKILLS[skill_id].related_skills

		scope = {'level': @level}
		for s_id, skill of board.SESSION_GLOBALS.SKILLS
			if parseInt(s_id) == skill_id
				scope[skill.title] = new_value
			else
				scope[skill.title] = @skills[s_id].base_value

		for rel_skill_id in related_skills
			rel_skill = board.SESSION_GLOBALS.SKILLS[rel_skill_id]
			formula = rel_skill.formula
			modified_value = evalWith formula, scope
			old_value = @skills[rel_skill_id].effective_value
			elem = rel_skill.get_char_elem @id

			html = "#{old_value}"
			if modified_value != old_value
				html = "#{old_value} <span style='color: green;'>(#{modified_value})</span>"
			elem.html html

	inc_skill: (category_id, skill_id) =>
		$category_elem = $ "#js-category-points-value-#{@id}-#{category_id}"
		points_left = parseInt $category_elem.html()

		if points_left > 0
			$value_elem = $ "#js-skill-value-#{@id}-#{skill_id} .js-value"
			old_value = $value_elem.html()
			new_value = parseInt(old_value) + 1
			$value_elem.html new_value
			$category_elem.html(points_left - 1)

			@changed_skills[skill_id] += 1
			@changed_categories[category_id] -= 1

			@related_skills_prompt skill_id, new_value

	dec_skill: (category_id, skill_id) =>
		$category_elem = $ "#js-category-points-value-#{@id}-#{category_id}"
		points_left = parseInt $category_elem.html()

		$value_elem = $ "#js-skill-value-#{@id}-#{skill_id} .js-value"
		old_value = $value_elem.html()
		new_value = parseInt(old_value) - 1

		if new_value >= @skills[skill_id].base_value
			$value_elem.html new_value
			$category_elem.html(points_left + 1)

			@changed_skills[skill_id] -= 1
			@changed_categories[category_id] += 1

			@related_skills_prompt skill_id, new_value

	put_item_on: (item_id) =>
		data = {
			'game_session_id': board.SESSION_GLOBALS.GAME_SESSION_ID,
			'item_id': item_id,
		}

		clb = (result) =>
			if result.success
				@items = result.items

				@render_dummy()
				@render_inventory()
			else
				console.log result
		board.SESSION_GLOBALS.WSCLIENT.request 'CharacterPutItemOn', data, clb

	take_item_off: (item_id) =>
		data = {
			'game_session_id': board.SESSION_GLOBALS.GAME_SESSION_ID,
			'item_id': item_id,
		}

		clb = (result) =>
			if result.success
				@items = result.items

				@render_dummy()
				@render_inventory()
			else
				console.log result
		board.SESSION_GLOBALS.WSCLIENT.request 'CharacterTakeItemOff', data, clb

	pick_up_playfield_object: (obj) =>
		data = {
			'game_session_id': board.SESSION_GLOBALS.GAME_SESSION_ID,
			'obj_id': obj.id,
		}

		clb = (result) =>
			if result.success
				@items = result.items

				@render_dummy()
				@render_inventory()

				obj.delete_elem()
			else
				console.log result
		board.SESSION_GLOBALS.WSCLIENT.request 'CharacterPickUpPlayfieldObject', data, clb

	save_skills: =>
		data = {
			'game_session_id': board.SESSION_GLOBALS.GAME_SESSION_ID,
		}

		num = 0
		for skill_id, value of @changed_skills
			if value == 0
				continue

			id_key = "skills-#{num}-id"
			val_key = "skills-#{num}-value"

			data[id_key] = skill_id
			data[val_key] = value

			num += 1

		clb = (result) =>
			if result.success
				@reset_data_to_apply()
				@skills = result.skills
			else
				console.log 'ERROR!', result
		board.SESSION_GLOBALS.WSCLIENT.request 'CharacterSaveSkills', data, clb

	do_sheet_binds: =>
		$('.js-inc-skill').bind 'click', (e) =>
			category_id = $(e.currentTarget).data 'categoryId'
			skill_id = $(e.currentTarget).data 'skillId'
			@inc_skill category_id, skill_id

		$('.js-dec-skill').bind 'click', (e) =>
			category_id = $(e.currentTarget).data 'categoryId'
			skill_id = $(e.currentTarget).data 'skillId'
			@dec_skill category_id, skill_id

		$('#js-characters-sheet-apply-btn').bind 'click', (e) =>
			e.preventDefault()
			@save_skills()