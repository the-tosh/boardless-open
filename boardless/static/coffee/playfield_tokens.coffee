# This library is a part of play.coffee. Code below was moved here for better readability

window.board.PlayfieldTokenFactory = (type, attrs) ->
	TYPE_TO_CLASS = {
		'item': ItemToken,
		'npc': NpcToken,
		'player': PlayerToken,
	}

	new TYPE_TO_CLASS[type](attrs)

class PlayfieldToken
	constructor: ({ @id, @title, @img_url, @point, @is_stored}) ->
		@last_click_time = null

		@changes = {}
		@prev_point = new board.Point @point.x, @point.y

	get_image: =>
		@img_url

	get_element_id: =>
		return "#js-play-object-#{@type}-#{@id}"

	get_element: =>
		return $ @get_element_id()

	apply_changes: =>
		if not @is_stored
			return

		if @changes.kill
			@kill()
			# return

		if @changes.point
			@save_point_to_db(@changes.point)

		@changes = {}

	update_general_data: (form_data) =>
		$elem = @get_element()

		for field in form_data
			switch field.name
				when 'title'
					@title = field.value
					$elem.find('span.js-play-object-title').html @title
				when 'id'
					continue

	save_general_data_to_db: (form_data) =>
		if not @is_stored
			@changes.general_data = []
			for field in form_data
				@changes.general_data.push(field)

		data = {
			'object_type': @type,
			'game_session_id': board.SESSION_GLOBALS.GAME_SESSION_ID,
		}
		for field in form_data
			data[field.name] = field.value

		clb = (result) =>
			if result.success
				console.log 'Object is updated!'
			else
				console.log 'Form errors!' # TODO: Fallback
		board.SESSION_GLOBALS.WSCLIENT.request 'UpdatePlayfieldToken', data, clb

	move_to: (point) =>
		$elem = @get_element()
		$elem.css({'left': point.x, 'top': point.y})

		@point = new board.Point point.x, point.y

	save_point_to_db: (point) =>
		if not @is_stored
			@changes.point = new board.Point point.x, point.y
			return

		data = {
			'game_session_id': board.SESSION_GLOBALS.GAME_SESSION_ID,
			'object_id': @id,
			'x': point.x,
			'y': point.y,
		}

		clb = (result) =>
			if result.success
				@prev_point = new board.Point @point.x, @point.y
			else
				console.log 'Form errors!'
				@move_to @prev_point
		board.SESSION_GLOBALS.WSCLIENT.request 'UpdatePlayfieldTokenPoint', data, clb

	delete_elem: =>
		$elem = @get_element()
		$elem.remove()

	kill: =>
		if not @is_stored
			# TODO: test
			@changes.kill = true
			return

		data = {
			'game_session_id': board.SESSION_GLOBALS.GAME_SESSION_ID,
			'id': @id,
		}

		clb = (result) =>
			if result.success
				@delete_elem()
			else
				console.log result.error
		board.SESSION_GLOBALS.WSCLIENT.request 'PlayfieldTokenDelete', data, clb

	set_db_id: (db_id) =>
		if @is_stored
			return

		$elem = @get_element()
		@id = db_id
		$elem.attr('id', "js-play-object-#{@type}-#{@id}")

	render: =>
		$obj = $ board.ECT.render '/static/js/templates/play/playfield_object.ect', {'object': @}
		$('#playfield').append $obj

	double_click_handler: =>
		if board.SESSION_GLOBALS.USER_ROLE == 'master'
			data = {'object': @}

			board.Popup.render_template("/play/update_#{@type}.ect", data, =>
				$("#js-update-#{@type}-form-ok-btn").bind 'click', =>
					board.Popup.hide()
					form_data = $("#js-update-#{@type}-container .js-update-#{@type}-form").serializeArray()

					@update_general_data(form_data)
					@save_general_data_to_db(form_data)
				$("#js-update-#{@type}-form-cancel-btn").bind 'click', =>
					board.Popup.hide()
				$("#js-update-#{@type}-form-delete-btn").bind 'click', =>
					board.Popup.hide()
					@kill()
			)

	enable_dragging: =>
		element_id = @get_element_id()
		interact(element_id).draggable {
				restrict: {
					restriction: '#playfield',
					elementRect: { top: 0, left: 0, bottom: 1, right: 1 },
				},
				onmove: (e) =>
					point = new board.Point @point.x + e.dx, @point.y + e.dy
					@move_to(point)
				onend: (e) =>
					@save_point_to_db(@point)
		}

	do_binds: =>
		$elem = @get_element()

		if board.SESSION_GLOBALS.USER_ROLE == "master"
			$elem.bind "dragstart", (e) ->
				e.preventDefault()

			@enable_dragging()

		$elem.bind "mousedown", (e) =>
			if @last_click_time? and (Date.now() - @last_click_time <= 0.3 * 1000)
				@last_click_time = null
				@double_click_handler()
			else
				@last_click_time = Date.now()

	after_creation: (new_id) =>
		@set_db_id new_id
		@enable_dragging()

		@is_stored = true
		@apply_changes()

class ItemToken extends PlayfieldToken
	constructor: ({ @id, @title, @img_url, @point, @item_id, @durability, @is_stored}) ->
		@last_click_time = null

		@changes = {}
		@prev_point = new board.Point @point.x, @point.y
		@type = 'item'

	update_general_data: (form_data) =>
		super form_data

		for field in form_data
			switch field.name
				when 'durability'
					@durability = field.value

	double_click_handler: =>
		if board.SESSION_GLOBALS.USER_ROLE == 'master'
			data = {'object': @, 'items': board.SESSION_GLOBALS.ITEMS}

			board.Popup.render_template('/play/update_item.ect', data, =>
				$('#js-update-item-form-ok-btn').bind 'click', =>
					board.Popup.hide()
					form_data = $("#js-update-#{@type}-container .js-update-#{@type}-form").serializeArray()

					# Adding a title
					for field in form_data
						if field.name == 'item'
							item_id = parseInt(field.value)
							break

					for item in board.SESSION_GLOBALS.ITEMS
						if item.id == item_id
							form_data.push({'name': 'title', 'value': item.title})

					@update_general_data(form_data)
					@save_general_data_to_db(form_data)
				$("#js-update-#{@type}-form-cancel-btn").bind 'click', =>
					board.Popup.hide()
				$("#js-update-#{@type}-form-delete-btn").bind 'click', =>
					board.Popup.hide()
					@kill()
			)
		else if board.SESSION_GLOBALS.THE_PLAYER?
			data = {'object': @}

			board.Popup.render_template('/play/take_item.ect', data, =>
				$('#js-take-item-form-ok-btn').bind 'click', =>
					board.Popup.hide()
					board.SESSION_GLOBALS.THE_PLAYER.pick_up_playfield_object(@)
				$('#js-take-item-form-cancel-btn').bind 'click', =>
					board.Popup.hide()
			)

class NpcToken extends PlayfieldToken
	constructor: (attrs) ->
		@type = 'npc'
		super attrs

class PlayerToken extends PlayfieldToken
	constructor: ({ @id, @title, @img_url, @point, @player_id, @is_stored}) ->
		@type = 'player'

		@changes = {}
		@prev_point = new board.Point @point.x, @point.y

	do_binds: =>
		$elem = @get_element()

		if board.SESSION_GLOBALS.USER_ROLE == "master"
			$elem.bind "dragstart", (e) ->
				e.preventDefault()

			element_id = @get_element_id()
			interact(element_id).draggable {
					restrict: {
						restriction: '#playfield',
						elementRect: { top: 0, left: 0, bottom: 1, right: 1 },
					},
					onmove: (e) =>
						point = new board.Point @point.x + e.dx, @point.y + e.dy
						@move_to(point)
					onend: (e) =>
						@save_point_to_db(@point)
			}