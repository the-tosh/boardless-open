class board.FormulaEditor
	constructor: (element_id) ->
		@element_id = element_id
		@dropdown_id = "js-#{@element_id}-autocomplete-dropdown"
		@keywords = ['level', 'self']
		@textarea = document.getElementById(element_id)
		@$textarea = $(@textarea)

		@create_dropdown()

		@dropdown = $("##{@dropdown_id}")
		@do_binds()

		@current_word_obj = null

	do_binds: =>
		@$textarea.bind "keydown", (event) ->
			if event.keyCode == 10 or event.keyCode == 13 then event.preventDefault()

		@$textarea.bind "keyup paste copy cut mouseup", (event) =>
			@match()

		

		# TODO: hide dropdown on the parent blur event

	match: =>
		@dropdown.empty()

		caret_position = @get_caret_position()

		text = $.trim @textarea.value
		if text
			parsed_names = PEG.parse text, {'startRule': 'Node'}

			for start_offset, word_obj of parsed_names
				if start_offset <= caret_position and word_obj.end_offset >= caret_position
					@current_word_obj = word_obj
					break

		if not @current_word_obj?
			return

		word = @current_word_obj.name

		matches = []
		if word.length >= 2
			for keyword in @keywords
				if keyword.indexOf(word) != -1
					if matches.indexOf(keyword) == -1 # TODO: Dict?
						matches.push keyword
						$('<p><div class="choice">' + keyword + '</div></p>').appendTo "##{@dropdown_id}"
						@dropdown.show()

		$("##{@dropdown_id} .choice").bind 'click', (e) =>
			@make_choice $(e.currentTarget).html()
			@dropdown.hide()

	get_caret_position: () ->
		position = 0

		if document.selection
			@textarea.focus()
			selection = document.selection.createRange()
			selection.moveStart 'character', -@textarea.value.length
			position = selection.text.length
		else if @textarea.selectionStart or @textarea.selectionStart == '0'
			position = @textarea.selectionStart

		return position

	add_keyword: (keyword) =>
		@keywords.push keyword

	create_dropdown: =>
		$('<div />', {id: @dropdown_id, style: "display: none; position: absolute; z-index: 10; background: white; padding: 5px;"}).appendTo @$textarea.parent()

	make_choice: (choice) =>
		if not @current_word_obj?
			return

		old_string = @textarea.value
		new_string = if @current_word_obj.start_offset then old_string[0..@current_word_obj.start_offset - 1] else ""
		new_string = "#{new_string}\"#{choice}\"#{old_string[@current_word_obj.end_offset..]}"
		@textarea.value = new_string

		@current_word_obj = null
		@dropdown.empty()
