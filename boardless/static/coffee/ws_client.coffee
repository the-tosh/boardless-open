class window.WSClient
	constructor: (@token) ->
		@url = "ws://#{window.board.WS_HOST}:#{window.board.WS_PORT}/playground"
		@request_id = null
		@callbacks = {}
		@actions = {}

		@create_connection()

	authenticate: =>
		data = {'action': 'Authenticate', 'params': {'token': @token}}
		@_send(data, @request_id)

	create_connection: =>
		settings = {'timeoutInterval': 1000, 'reconnectInterval': 3000, 'reconnectDecay': 1.0, 'debug': false}

		@connection = new ReconnectingWebSocket @url, null, settings
		@connection.onopen = @on_open
		@connection.onerror = @error_handler
		@connection.onmessage = @receive_handler
		@connection.onclose = @on_close

		window.onbeforeunload = =>
			@connection.close()

	on_open: (event) =>
		console.log 'Connection established'
		@authenticate()

	on_close: (event) ->
		console.log 'Connection was closed'

	error_handler: (error) ->
		console.log error
		console.log "WebSocket Error!", error

	receive_handler: (event) =>
		data = JSON.parse event.data

		console.log "Data was received: ", data

		if data.request_id
			if @callbacks[data.request_id]?
				@callbacks[data.request_id](data)
				@callbacks[data.request_id] = null

		if data.call_action
			if @actions[data.call_action]?
				for clb in @actions[data.call_action]
					clb(data.params)
				# TODO: run_once param?

		if data.is_authorized
			@request_id = 1

	request: (action, params, clb) =>
		console.log 'Request:', action, params, clb
		if @request_id
			tmp_request_id = @request_id += 1 # Prevents race conditions
			if clb
				@callbacks[tmp_request_id] = clb
			data = {'action': action, 'params': params}
			@_send data, tmp_request_id
		else
			console.log 'Waiting for auth'
			setTimeout =>
				@request action, params, clb
			, 1500

	_send: (data, request_id) =>
		# Encapsulation!!!
		# Do not call this method outside of the parent class
		if request_id?
			data['params']['request_id'] = request_id

		@connection.send(JSON.stringify(data))

	register_action: (name, clb) =>
		console.log "Register action for name #{name}"
		if not @actions[name]?
			@actions[name] = []

		@actions[name].push(clb)

class window.DummyClient
	constructor: () ->
	request: (action, params, clb) =>
