### Name Spaces ###

window.board = {}

window.board.ECT = ECT()

#############################################################
# Helpers
#############################################################

board.static_url = (path) ->
	return "#{window.location.origin}/static/#{path}"

board.numeric_with_sign = (num) ->
	if num > 0
		return "+#{num}"
	else if num < 0
		return "#{num}"
	return "0"

class board.Popup
	# Static methods (singleton-like usage)
	@show: ->
		$('#js-popup').removeClass('hidden')

	@hide: ->
		$('#js-popup').addClass('hidden')

	@render_template: (tpl_path, context, callback) ->
		$('#js-popup-container').html board.ECT.render "/static/js/templates/popup#{tpl_path}", context
		board.Popup.show()

		$('.popup__close').bind 'click', (e) =>
			do e.preventDefault
			@hide()
			return

		if callback?
			callback()

	@clean: ->
		$('#js-popup-container').empty()

class board.Feedback
	constructor: ->
		@$elem = $('#feedback_modal')
		@do_binds()

	open: =>
		@$elem.fadeIn()

	close: =>
		@$elem.fadeOut()

	do_binds: =>
		$('#feedback-modal-open').bind 'click', (e) =>
			do e.preventDefault
			@open()

		$('#feedback-modal-close').bind 'click', (e) =>
			do e.preventDefault
			@close()

		$('#feedback-send').bind 'click', (e) =>
			$form = $('#feedback-form')
			data = {'page': document.URL}
			for el in $form.serializeArray()
				data[el.name] = el.value

			$.ajax
				type: 'POST'
				url: '/feedback/'
				data: data
				success: (data, textStatus, jqXHR) =>
					@$elem.find('.error').empty()
					$('#feedback-form').trigger('reset')
					@close()
					runNoty("Feedback was sent")
				error: (jqXHR, textStatus, errorThrown) =>
					response = jqXHR.responseJSON
					if jqXHR.status == 422
						errors = response.errors
						for field_name, field_errors of errors
							$error = @$elem.find(".error[for=#{field_name}]")
							$error.html(field_errors[0])


board.runAjax = (type, url, data, _method, __this) ->
	if url? and data?
		$.ajax
			type: type
			url: url
			data: data
			success: (data, textStatus, jqXHR) ->
				if _method?
					#_method {type: "success", data: data, _this: __this}
					_method.call __this, {type: "success", data: data}
				return
			error: (jqXHR, textStatus, errorThrown) ->
				_method.call __this, {type: "error", data: errorThrown}
				return

	else
		console.log "No required arguments"

window.runNoty = (text, type = "information") ->
	#noty types: Alert, Success, Error, Warning, Information, Confirm 
	noty
		text        : text
		type        : type
		dismissQueue: true
		layout      : 'topRight'
		theme       : 'defaultTheme'
		timeout: 10000
	return

window.str_to_fun = (functionName) ->
	arr = functionName.split "."
	for el, i in arr
		if i == 0
			fun = window[el]
		else
			fun = fun[el]
	fun

window.add_hash = (data)->
	window.location.hash = "message=#{ data }"
	do window.location.reload

window.cache_observer = () ->
	hash = window.location.hash
	if hash != ""
		if hash.indexOf("message") != -1
			runNoty hash.split("=")[1]
			window.location.hash = ""

open_form = ()->
	$(".opener-btn").on "click", (e) ->
		do e.preventDefault
		target_btn = $(e.target)
		form = target_btn.parent().parent().find("form")
		form.removeClass("hidden")
		do target_btn.hide
		
		form.find(".cansel-btn").one "click", (e)->
			do e.preventDefault
			btn = $(e.target)
			btn.parent().parent("form").addClass("hidden")
			btn.parent().parent().parent().find("a.opener-btn").show()
			return
		return

###    Definitions    ###
$.noty.layouts.topRight = {
	name: 'topRight'
	container: {
		object: '<ul id="noty_topRight_layout_container" />'
		selector: 'ul#noty_topRight_layout_container'
		style: () ->
			$(this).css({
				top: 20
				right: 20
				position: 'fixed'
				width: '310px'
				height: 'auto'
				margin: 0
				padding: 0
				listStyleType: 'none'
				zIndex: 10000000
			})

			#if window.innerWidth < 600
				#$(this).css({right: 5})
	}
	parent: {
		object: '<li />'
		selector: 'li'
		css: {}
	}
	css: {
		display: 'none'
		width: '310px'
	}
	addClass: ''
}


###    On document is ready()    ###
$ () ->
	#do $(".nano").nanoScroller
	do cache_observer
	do open_form

	if document.getElementsByClassName('stuff').length > 0
		items = new board.Items document.getElementsByClassName('stuff')[0]

	# validate_obj = $(".validate-this-button")
	# if validate_obj?
	# 	validate_obj_arr = []
	# 	for obj, i in validate_obj
	# 			validate_obj_arr[i] = new board.ValidateForm obj
	# 		do validate_obj_arr[i].init

	# $(".js-select2").select2()

	new board.Feedback()