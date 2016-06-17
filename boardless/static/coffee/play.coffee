board.SESSION_GLOBALS = {
	'GAME_SESSION_ID': null,
	'USER_ROLE': null,
	'ITEMS': null,
	'WSCLIENT': null,
	'THE_PLAYER': null,
	'MASTER': null,
	'CHARACTERS': null,
	'TOKEN_TOOLS': null,
}

class window.PlayManager
	constructor: (game_session_id, user_role, @cols_for_char_tbl, @characters_data, @the_player_id, @skills, @item_groups, @skills_categories, items, @character_token, @dices, @master_id, token_tools) ->

		@init_globals(game_session_id, user_role, items, token_tools)
		@init_ws()
		@init_characters()

		@init_playfield()
		@init_user()
		@init_character_sheet()

		@init_grid()

		@init_dices()

		@do_ws_binds()

	init_globals: (game_session_id, user_role, items, token_tools) ->
		board.SESSION_GLOBALS = {
			'GAME_SESSION_ID': game_session_id,
			'USER_ROLE': user_role,
			'ITEMS': items,
			'SKILLS': {},
			'WSCLIENT': null,
			'THE_PLAYER': null,
			'MASTER': null,
			'CHARACTERS': {},
			'TOKEN_TOOLS': token_tools,
		}

		for skill_id, skill_data of @skills
			skill = new board.Skill skill_data
			board.SESSION_GLOBALS.SKILLS[skill.id] = skill

	init_characters: =>
		for character_data in @characters_data
			character = new board.Character character_data
			board.SESSION_GLOBALS.CHARACTERS[character.id] = character

		data = {'game_session_id': board.SESSION_GLOBALS.GAME_SESSION_ID}
		clb = (result) =>
			if result.success
				@set_master_status result.master_is_online

				for char_id in result.online_players_ids
					board.SESSION_GLOBALS.CHARACTERS[char_id].join()
				board.EventDispatcher.emmit('received_online_players', {'ids': result.online_players_ids})
			else
				console.log result
		board.SESSION_GLOBALS.WSCLIENT.request 'GetOnlinePlayers', data, clb

	set_master_status: (status) =>
		$elem = $('#js-master-data')
		if status
			$elem.removeClass('half-opaque')
		else
			$elem.addClass('half-opaque')

	init_user: =>
		switch board.SESSION_GLOBALS.USER_ROLE
			when "player"
				if @the_player_id? and @the_player_id != -1
					for character_data in @characters_data
						if character_data.id == @the_player_id
							char_dict = {'item_groups': @item_groups}
							$.extend(char_dict, character_data)
							new board.ThePlayer char_dict

							return
			when "master"
				new board.Master()
				return

	init_playfield: =>
		@playfield = new Playfield()

	init_character_sheet: =>
		@character_sheet = new CharacterSheet @cols_for_char_tbl

	init_grid: =>
		grid = new Grid()
		grid.draw_hexagon_grid()

	init_dices: =>
		dm = new DiceManager(@dices)

	init_ws: =>
		if @character_token?
			board.SESSION_GLOBALS.WSCLIENT = new WSClient @character_token
		else
			board.SESSION_GLOBALS.WSCLIENT = new DummyClient()

	do_ws_binds: =>
		board.SESSION_GLOBALS.WSCLIENT.register_action 'CharacterJoined', (params) =>
			character_data = params.character

			if character_data.id == @master_id
				@set_master_status true
				return

			character = board.SESSION_GLOBALS.CHARACTERS[character_data.id]
			if not character?
				board.SESSION_GLOBALS.CHARACTERS[character_data.id] = new board.Character character_data
				character = board.SESSION_GLOBALS.CHARACTERS[character_data.id]
			character.join()

			@character_sheet.character_joined(character.id)
			@playfield.toolbox.render_avatars()

		board.SESSION_GLOBALS.WSCLIENT.register_action 'CharacterDisconnected', (params) =>
			character_id = params.character_id

			if character_id == @master_id
				@set_master_status false
				return

			character = board.SESSION_GLOBALS.CHARACTERS[character_id]
			character.disconnect()
			@character_sheet.character_joined(character.id)
			@playfield.toolbox.render_avatars()

class DiceManager
	constructor: (@dices) ->
		@$dice_window = $('#js-dices')
		@point = new board.Point @$dice_window.offset().left, @$dice_window.offset().top

		@do_binds()
		@do_ws_binds()

	move_window: (point) =>
		@$dice_window.css({'left': point.x, 'top': point.y})
		@point = point

	do_ws_binds: =>
		board.SESSION_GLOBALS.WSCLIENT.register_action 'RollDiceResults', (params) =>
			$res_elem = $('#js-dice-results')
			$res_elem.empty()
			for i of params.results
				res = params.results[i]
				dice_id = parseInt(res.id)
				dice = @dices[dice_id]
				console.log 'dice', dice
				html = board.ECT.render '/static/js/templates/play/dice.ect', {'dice': dice, 'value': res.value}
				$res_elem.append html

	do_binds: =>
		if board.SESSION_GLOBALS.USER_ROLE == 'master'
			$('.js-base-dice').bind 'click', (e) =>
				dice2add = $(e.currentTarget).clone()
				dice2add.removeClass('js-base-dice')
				dice2add.addClass('js-selected-dice')
				dice2add.bind 'click', (e) =>
					$(e.currentTarget).remove()
				$('#js-selected-dices').append(dice2add)

			$('#js-roll-dice').bind 'click', (e) =>
				dices = {}
				$('.js-selected-dice').each (idx, elem) =>
					dices["dices_ids-#{idx}"] = parseInt($(elem).attr('dice-id'))
				board.SESSION_GLOBALS.WSCLIENT.request 'RollDices', dices

			$('#js-dices-reset').bind 'click', (e) ->
				$('#js-selected-dices').empty()

		interact('#js-dices').draggable {
				restrict: {
						restriction: 'body',
						elementRect: { top: 0, left: 0, bottom: 1, right: 1 },
				},
				onmove: (e) =>
					point = new board.Point @point.x + e.dx, @point.y + e.dy
					@move_window(point)
		}

class Tool
	constructor: (color, size, type, extra) ->
		@color = color or "#000000"
		@size = size or 1
		@type = type or "brush"
		@extra = extra or {}

class Toolbox
	constructor: (@playfield) ->
		if board.SESSION_GLOBALS.USER_ROLE != "master"
			return

		@tool = new Tool()

		@render_drawing_tools()
		@init_color_picker()
		@init_size_slider()
		@render_token_tools()
		@render_avatars()

		@highlight_init_tool()

		@do_binds()
		@listen_events()

	highlight_init_tool: =>
		$('.js-toolbox-set-tool[data-tool=brush]').addClass('js-active-tool')

	render_drawing_tools: =>
		$object_elem = $('#js-toolbox-drawing-tools')
		html = board.ECT.render '/static/js/templates/play/toolbox_drawing_tools.ect', {'board': board}
		$object_elem.html(html)

	render_token_tools: =>
		$object_elem = $('#js-toolbox-token-tools')
		result_html = ''
		for obj in board.SESSION_GLOBALS.TOKEN_TOOLS
			data = {'obj': obj}
			html = board.ECT.render '/static/js/templates/play/toolbox_tokens.ect', data
			result_html = "#{result_html}\n#{html}"

		$object_elem.html(result_html)

		# New item
		$('#js-choose-item').bind 'click', (e) =>
			board.Popup.render_template('/play/new_item.ect', {'items': board.SESSION_GLOBALS.ITEMS}, =>
				$('#js-new-item-form-ok-btn').bind 'click', (e) =>
					board.Popup.hide()
					@playfield.move_el_to_proxy_container '#js-new-item-container .js-new-item-form'
					board.Popup.clean()
					$('.js-active-tool').removeClass('js-active-tool')
					$('#js-choose-item').addClass('js-active-tool')
					@set_tool $('#js-choose-item').data 'tool'

				$('#js-new-item-form-cancel-btn').bind 'click', (e) =>
					board.Popup.hide()
				$(".js-select2").select2()
		)

		# New NPC
		$('#js-choose-npc').bind 'click', (e) =>
			board.Popup.render_template('/play/new_npc.ect', {}, =>
				$('#js-new-npc-form-ok-btn').bind 'click', (e) =>
					board.Popup.hide()
					@playfield.move_el_to_proxy_container '#js-new-npc-container .js-new-npc-form'
					board.Popup.clean()
					$('.js-active-tool').removeClass('js-active-tool')
					$('#js-choose-npc').addClass('js-active-tool')
					@set_tool $('#js-choose-npc').data 'tool'

				$('#js-new-npc-form-cancel-btn').bind 'click', (e) =>
					board.Popup.hide()
		)

	render_avatars: =>
		$objects_elem = $('#js-toolbox-players-avatars')

		result_html = ''
		for character_id, character of board.SESSION_GLOBALS.CHARACTERS
			data = {'character': character}
			html = board.ECT.render '/static/js/templates/play/toolbox_character.ect', data
			result_html = "#{result_html}\n#{html}"

		$objects_elem.html(result_html)

		@do_set_tool_binds()

	init_color_picker: =>
		$('#js-color-palette').spectrum({
			showPaletteOnly: true,
			togglePaletteOnly: true,
			togglePaletteMoreText: 'more',
			togglePaletteLessText: 'less',
			color: '#000',
			showInitial: true,
			palette: [
				["#000","#444","#666","#999","#ccc","#eee","#f3f3f3","#fff"],
				["#f00","#f90","#ff0","#0f0","#0ff","#00f","#90f","#f0f"],
				["#f4cccc","#fce5cd","#fff2cc","#d9ead3","#d0e0e3","#cfe2f3","#d9d2e9","#ead1dc"],
				["#ea9999","#f9cb9c","#ffe599","#b6d7a8","#a2c4c9","#9fc5e8","#b4a7d6","#d5a6bd"],
				["#e06666","#f6b26b","#ffd966","#93c47d","#76a5af","#6fa8dc","#8e7cc3","#c27ba0"],
				["#c00","#e69138","#f1c232","#6aa84f","#45818e","#3d85c6","#674ea7","#a64d79"],
				["#900","#b45f06","#bf9000","#38761d","#134f5c","#0b5394","#351c75","#741b47"],
				["#600","#783f04","#7f6000","#274e13","#0c343d","#073763","#20124d","#4c1130"]
			]
			change: (color) =>
				@set_color color.toHexString()
			,
		})

	init_size_slider: =>
		$('#js-size-slider').slider({
			min: 1,
			max: 10,
			value: 1,

			change: (event, ui) =>
				@set_size ui.value
		})

	set_size: (size) =>
		@tool.size = size
		@playfield.drawer.context.lineWidth = size

	set_color: (color) =>
		@tool.color = color
		@playfield.drawer.context.strokeStyle = color
		@playfield.drawer.context.fillStyle = color

	show_related_tool_settings: (tool_type) =>
		$(".js-tool-related.js-#{tool_type}-related").show()
		$(".js-tool-related:not(.js-#{tool_type}-related)").hide()

	set_tool: (tool_type) =>
		@show_related_tool_settings tool_type

		switch tool_type
			when "brush"
				@tool.type = tool_type
				@playfield.drawer.context.strokeStyle = @tool.color
				@playfield.drawer.context.fillStyle = @tool.color
			when "eraser"
				@tool.type = tool_type
			when "playfield-object"
				@tool.type = tool_type
				$element = $('.js-active-tool:first')

				@tool.extra = {
					'type': $element.data('objectType'),
					'img_url': $element.data('imgUrl'),
					'title': $element.data('title'),
				}

				switch @tool.extra.type
					when 'player'
						@tool.extra['player_id'] = parseInt $element.data 'playerId'
					when 'item'
						for field in $('#js-active-tool-hidden-proxy-container .js-new-item-form').serializeArray()
							@tool.extra[field.name] = field.value
							item_id = parseInt(@tool.extra.item)

							for item in board.SESSION_GLOBALS.ITEMS
								if item.id == item_id
									@tool.extra.title = item.title
									break
					when 'npc'
						for field in $('#js-active-tool-hidden-proxy-container .js-new-npc-form').serializeArray()
							@tool.extra[field.name] = field.value

	apply_tool: (tool_type) =>
		switch tool_type
			when "clear"
				@playfield.drawer.context.clearRect(0, 0, @playfield.drawer.width, @playfield.drawer.height)
				@playfield.save_image()

	do_binds: =>
		$('.js-toolbox-set-size').bind 'click', (e) =>
			@set_size $(e.currentTarget).data 'size'

		$('.js-toolbox-apply-tool').bind 'click', (e) =>
			@apply_tool $(e.currentTarget).data 'tool'

		@do_set_tool_binds()

	do_set_tool_binds: =>
		$('.js-toolbox-set-tool').unbind 'click'
		$('.js-toolbox-set-tool').bind 'click', (e) =>
			$this = $(e.currentTarget)
			$('.js-active-tool').removeClass('js-active-tool')
			$this.addClass('js-active-tool')

			@set_tool $this.data 'tool'

	listen_events: =>
		board.EventDispatcher.listen 'received_online_players', (e) =>
			@render_avatars()

class Playfield
	constructor: ->
		@toolbox = new Toolbox(@)
		@drawer = new Drawer()

		@init_objects {}
		@load()

		if board.SESSION_GLOBALS.USER_ROLE == "master"
			@do_binds()

		@do_ws_binds()

	move_el_to_proxy_container: (selector_to_move) ->
		$elem = $(selector_to_move).detach()
		$('#js-active-tool-hidden-proxy-container').html $elem

	init_objects: (tokens_data) =>
		@play_tokens = {
			"npc": {},
			"item": {},
			"player": {},
		}
		@tmp_play_tokens = {} # TODO: Do not recreate objects

		for token_data in tokens_data
			init_attrs = {}
			for k, v of token_data
				switch k
					when 'x', 'y'
						continue
					else
						init_attrs[k] = v

			init_attrs.point = new board.Point parseFloat(token_data.x), parseFloat(token_data.y)
			init_attrs.is_stored = true

			token = board.PlayfieldTokenFactory token_data.type_string, init_attrs

			token.extra = token_data.attrs

			@play_tokens[token_data.type_string][token.id] = token
			token.delete_elem()
			token.render()
			token.do_binds() # TODO: Reduce copypaste?

	add_object: (point) =>
		_d = new Date()
		tmp_key = _d.getTime().toString()
		init_attrs = {}

		for k, v of @toolbox.tool.extra
			switch k
				when 'x', 'y', 'id'
					continue
				else
					init_attrs[k] = v

		init_attrs.id = tmp_key
		init_attrs.point = point
		init_attrs.is_stored = false

		token = board.PlayfieldTokenFactory @toolbox.tool.extra.type, init_attrs
		@tmp_play_tokens[tmp_key] = token
		token.render()
		token.do_binds()

		_d = undefined

		data = {
			'game_session_id': board.SESSION_GLOBALS.GAME_SESSION_ID,
			'tmp_key': tmp_key,
			'object_type': token.type,
			'x': token.point.x,
			'y': token.point.y,
			'title': token.title,
		}

		for field_name, field_value of @toolbox.tool.extra
			data[field_name] = field_value
			token[field_name] = field_value

		clb = (result) =>
			if result.success
				token = @tmp_play_tokens[result.tmp_key]
				token.after_creation result.object_id

				@play_tokens[token.type][result.object_id] = token
				@tmp_play_tokens[result.tmp_key] = undefined

				if token.type == 'player'
					token.player_id = result.player_id

			else
				tmp_key = result.tmp_key or data.tmp_key
				token = @tmp_play_tokens[tmp_key]
				token.delete_elem()
				@tmp_play_tokens[tmp_key] = undefined

		board.SESSION_GLOBALS.WSCLIENT.request 'PlayfieldTokenCreate', data, clb


	do_binds: =>
		@drawer.$canvas.bind 'mousedown', (e) =>
			offset = $(e.currentTarget).parent().offset()
			point = new board.Point e.pageX - (offset.left || 0), e.pageY - (offset.top || 0)

			switch @toolbox.tool.type
				when 'playfield-object'
					if @toolbox.tool.extra.type == 'player'
						for token_id, token of @play_tokens['player']
							if token.player_id == @toolbox.tool.extra.player_id
									token.move_to(point)
									token.save_point_to_db(point)
									return

					@add_object(point)
				else
					@drawer.is_dragging = true
					@drawer.draw @toolbox.tool, point
					@drawer.previous_point = point

		@drawer.$canvas.bind 'mousemove', (e) =>
			if @drawer.is_dragging
				offset = $(e.currentTarget).parent().offset()
				point = new board.Point e.pageX - (offset.left || 0), e.pageY - (offset.top || 0)
				@drawer.draw @toolbox.tool, point
				@drawer.previous_point = point

		@drawer.$canvas.bind 'mouseup mouseleave', (e) =>
			if @drawer.is_dragging
				@drawer.is_dragging = false
				@drawer.previous_point = null
				@save_image()

	do_ws_binds: =>
		if board.SESSION_GLOBALS.USER_ROLE != "master"
			board.SESSION_GLOBALS.WSCLIENT.register_action 'ReloadPlayfield', (params) =>
				@load()

			board.SESSION_GLOBALS.WSCLIENT.register_action 'MovePlayfieldObject', (params) =>
				token_type = params.obj_type
				token_id = params.obj_id
				token = @play_tokens[token_type][token_id]

				if token?
					point = new board.Point parseFloat(params.x), parseFloat(params.y)
					token.move_to(point)

		board.SESSION_GLOBALS.WSCLIENT.register_action 'DeletePlayfieldObject', (params) =>
				token_type = params.obj_type
				token_id = params.obj_id
				token = @play_tokens[token_type][token_id]

				if token?
					token.delete_elem()

	save_image: =>
		image = @drawer.canvas.toDataURL "image/png"

		clb = (result) =>
			if result.success
				console.log 'ok' # TODO
			else
				console.log 'error' # TODO
		data = {'game_session_id': board.SESSION_GLOBALS.GAME_SESSION_ID, 'image': image}
		board.SESSION_GLOBALS.WSCLIENT.request 'SaveImage', data, clb

	load: =>
		clb = (result) =>
			if result.success
				image = new Image()
				image.src = result.image
				image.onload = =>
					width = $('#canvas_draw').width()
					height = $('#canvas_draw').height()
					@drawer.context.clearRect 0, 0, width, height
					@drawer.context.drawImage image, 0, 0

				@init_objects(result.playfield_objects)
			else
				console.log 'error', textStatus # TODO
		board.SESSION_GLOBALS.WSCLIENT.request 'LoadPlayfield', {'game_session_id': board.SESSION_GLOBALS.GAME_SESSION_ID}, clb

class board.Point
	constructor: (x, y) ->
		@x = x
		@y = y

class Drawer
	constructor: () ->
		@canvas = document.getElementById "canvas_draw"
		@context = @canvas.getContext "2d"
		@$canvas = $ @canvas
		@is_dragging = false
		@previous_point = null
		@width = $('#canvas_draw').width()
		@height = $('#canvas_draw').height()

		@setup_context()

	setup_context: =>
		@context.strokeStyle = @TOOL_COLOR
		@context.fillStyle = @TOOL_COLOR
		@context.lineWidth = @TOOL_SIZE
		@context.lineJoin = "round"

	draw: (tool, point) =>
		switch tool.type
			when "eraser"
				eraser_size = tool.size * 1.5
				@context.clearRect(point.x, point.y, eraser_size, eraser_size);

			when "brush"
				RADIUS = @context.lineWidth / 2
				@context.beginPath()

				if @previous_point
					@context.moveTo @previous_point.x, @previous_point.y
					@context.lineTo point.x, point.y
					@context.closePath()
					@context.stroke()

				else
					@context.arc point.x, point.y, RADIUS, 0, Math.PI * 2, false
					@context.closePath()
					@context.fill()

class Grid
	constructor: ->
		@COLOR = "#a3a3a3"
		@LINE_WIDTH = 1
		@SIDE_SIZE = 35
		@GRID_WIDTH = 1010
		@GRID_HEIGHT = 510

		@canvas = document.getElementById "canvas_grid"
		@context = @canvas.getContext "2d"
		@context.strokeStyle = @COLOR
		@context.lineWidth = @LINE_WIDTH

	draw_polygon: (edges_amount, center_x, center_y) ->
		for edge_num in [0 .. edges_amount]
			angle = 2 * Math.PI / edges_amount * (edge_num + 0.5)
			edge_x = center_x + @SIDE_SIZE / 2 * Math.cos angle
			edge_y = center_y + @SIDE_SIZE / 2 * Math.sin angle

			if not edge_num
				@context.moveTo edge_x, edge_y
			else
				@context.lineTo edge_x, edge_y

	draw_square_grid: ->
		for x in [0 .. @GRID_WIDTH] by @SIDE_SIZE
			@context.moveTo 0.5 + x, 0
			@context.lineTo 0.5 + x, @GRID_HEIGHT


		for y in [0 .. @GRID_HEIGHT] by @SIDE_SIZE
			@context.moveTo 0, 0.5 + y
			@context.lineTo @GRID_WIDTH, 0.5 + y

		@context.stroke()

	draw_hexagon_grid: =>
		HALF_SIDE = @SIDE_SIZE / 2
		height = @SIDE_SIZE
		vert_dist = 3 / 4 * height
		width = Math.sqrt(3) / 2 * height
		horiz_dist = width

		for center_x in [HALF_SIDE .. @GRID_WIDTH] by horiz_dist
			is_even = true
			for center_y in [HALF_SIDE .. @GRID_HEIGHT] by vert_dist
				is_even = not is_even
				offset = 0
				if is_even
					offset = HALF_SIDE / 2 * Math.sqrt 3

				@draw_polygon 6, center_x + offset, center_y

		@context.stroke()

class CharacterSheet
	constructor: (@cols_for_char_tbl) ->
		@$elem = $('#js-characters-sheet')

		@render_skills_table()
		@do_ws_binds()
		@listen_events()

	render_skills_table: =>
		data = {
			'characters': board.SESSION_GLOBALS.CHARACTERS,
			'cols_for_char_tbl': @cols_for_char_tbl,
			'skills': board.SESSION_GLOBALS.SKILLS,
			'the_player': board.SESSION_GLOBALS.THE_PLAYER,
			'master': board.SESSION_GLOBALS.MASTER,
		}
		html = board.ECT.render '/static/js/templates/play/characters_sheet.ect', data
		@$elem.html(html)

		board.SESSION_GLOBALS.THE_PLAYER? and board.SESSION_GLOBALS.THE_PLAYER.do_sheet_binds()
		board.SESSION_GLOBALS.MASTER? and board.SESSION_GLOBALS.MASTER.do_sheet_binds()

	character_joined: (character_id) =>
		@render_skills_table()

	character_disconnected: (character_id) =>
		$elem = $("#js-characters-sheet-character-row-#{character_id}")
		$elem? and $elem.addClass('half-opaque')

	do_ws_binds: =>
		# For players and spectators only
		# if board.SESSION_GLOBALS.USER_ROLE != "master"
		#	board.SESSION_GLOBALS.WSCLIENT.register_action 'MasterChangedCategoryPoints', (params) =>
		#		for data_tpl in params.data_tpls
		#			character_id = data_tpl[0]
		#			category_id = data_tpl[1]
		#			new_value = data_tpl[2]

		#			character = board.SESSION_GLOBALS.CHARACTERS[character_id]
		#			character.skill_points[category_id] = new_value

		#			if board.SESSION_GLOBALS.THE_PLAYER? and board.SESSION_GLOBALS.THE_PLAYER == character
		#				board.SESSION_GLOBALS.THE_PLAYER.skill_points[category_id] = new_value

		#				if board.SESSION_GLOBALS.THE_PLAYER.changed_categories[category_id]?
		#					board.SESSION_GLOBALS.THE_PLAYER.skill_points[category_id] -= board.SESSION_GLOBALS.THE_PLAYER.changed_categories[category_id]

		#		@render_skills_table()

		update_characters = (params) =>
			for char_id, character_data of params.characters
				character = board.SESSION_GLOBALS.CHARACTERS[character_data.id]
				character.update_params(character_data)

				if board.SESSION_GLOBALS.THE_PLAYER? and character == board.SESSION_GLOBALS.THE_PLAYER
					board.SESSION_GLOBALS.THE_PLAYER.update_params(character_data)

		# Update players info
		board.SESSION_GLOBALS.WSCLIENT.register_action 'CharactersXpChanged', (params) =>
			update_characters(params)
			@render_skills_table()

		# For all members
		update_character = (params) =>
			# {character_id: {skills: ..., items: ...}}
			character = board.SESSION_GLOBALS.CHARACTERS[params.character_id]
			character.update_params(params)

			if board.SESSION_GLOBALS.THE_PLAYER? and character == board.SESSION_GLOBALS.THE_PLAYER
				board.SESSION_GLOBALS.THE_PLAYER.update_params(params)

			@render_skills_table()

		board.SESSION_GLOBALS.WSCLIENT.register_action 'AfterCharacterPutItemOn', update_character
		board.SESSION_GLOBALS.WSCLIENT.register_action 'AfterCharacterTookItemOff', update_character

		board.SESSION_GLOBALS.WSCLIENT.register_action 'AfterCharacterChangeSkills', (params) =>
			character = board.SESSION_GLOBALS.CHARACTERS[params.character_id]
			character.skills = params.skills
			character.skill_points = params.skill_points

			if board.SESSION_GLOBALS.THE_PLAYER? and character == board.SESSION_GLOBALS.THE_PLAYER
				board.SESSION_GLOBALS.THE_PLAYER.skills = params.skills
				board.SESSION_GLOBALS.THE_PLAYER.skill_points = params.skill_points

			@render_skills_table()

	listen_events: =>
		board.EventDispatcher.listen 'received_online_players', (e) =>
			@render_skills_table()