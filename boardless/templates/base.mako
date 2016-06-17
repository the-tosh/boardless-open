<!DOCTYPE html>
<html>
	<head>
		<link rel="shortcut icon" type="image/vnd.microsoft.icon" href="${request.static_url('boardless:static/favicon.ico')}?v=1">

		<link href='http://fonts.googleapis.com/css?family=Open+Sans+Condensed:300,700&subset=latin,cyrillic' rel='stylesheet' type='text/css'>
		<link href="${request.static_url('boardless:static/css/styles.css')}" rel="stylesheet" media="screen">
		<link href="${request.static_url('boardless:static/css/select2.min.css')}" rel="stylesheet" />
		<link href="${request.static_url('boardless:static/css/spectrum.min.css')}" rel="stylesheet" />
		<link href="${request.static_url('boardless:static/css/feedback.css')}" rel="stylesheet" />
		<link href="${request.static_url('boardless:static/css/jquery-ui.css')}" rel="stylesheet" />

		<%block name="styles"></%block>


		## JQuery
		<script src="${request.static_url('boardless:static/js/jquery-2.1.0.min.js')}" type="text/javascript"></script>
		<script src="${request.static_url('boardless:static/js/jquery.nanoscroller.min.js')}" type="text/javascript"></script>
		<script src="${request.static_url('boardless:static/js/jquery.noty.packaged.min.js')}" type="text/javascript"></script>
		<script src="${request.static_url('boardless:static/js/jquery-ui.js')}"></script>

		<script src="${request.static_url('boardless:static/js/select2.min.js')}"></script>
		<script src="${request.static_url('boardless:static/js/interact-1.2.4.min.js')}"></script>
		<script src="${request.static_url('boardless:static/js/reconnecting-websocket.min.js')}"></script>
		<script src="${request.static_url('boardless:static/js/spectrum.min.js')}" type="text/javascript"></script>

		## Grammatics
		## TODO: How to use multiple grammatics? (With "scopes", i.e. simple explicit naming can solve the problem)
		<script src="${request.static_url('boardless:static/grammatics/compiled/grammatics.js')}" type="text/javascript"></script>


		## Templater (and CS for it)
		<script src="${request.static_url('boardless:static/js/coffee-script.min.js')}" type="text/javascript"></script>
		<script src="${request.static_url('boardless:static/js/ect.min.js')}" type="text/javascript"></script>

		## Various stuff which can not be implemented in CoffeeScript
		<script src="${request.static_url('boardless:static/js/js_helpers.js')}" type="text/javascript"></script>

		## Compiled coffeescript
		<script src="${request.static_url('boardless:static/js/compiled/main.js')}" type="text/javascript"></script>
		<script src="${request.static_url('boardless:static/js/compiled/events.js')}" type="text/javascript"></script>
		<script src="${request.static_url('boardless:static/js/compiled/formula.js')}" type="text/javascript"></script>

		## Auto-generated settings file. Must be here because it uses namespaces from main.js and is used by ws_client.js
		<script src="${request.static_url('boardless:static/js/compiled/settings.js')}" type="text/javascript"></script>

		<script src="${request.static_url('boardless:static/js/compiled/ws_client.js')}" type="text/javascript"></script>
		<script src="${request.static_url('boardless:static/js/compiled/rules_new.js')}" type="text/javascript"></script>
		<script src="${request.static_url('boardless:static/js/compiled/rules.js')}" type="text/javascript"></script>
		<script src="${request.static_url('boardless:static/js/compiled/playfield_tokens.js')}" type="text/javascript"></script>
		<script src="${request.static_url('boardless:static/js/compiled/character.js')}" type="text/javascript"></script>
		<script src="${request.static_url('boardless:static/js/compiled/play.js')}" type="text/javascript"></script>
		<script src="${request.static_url('boardless:static/js/compiled/char_setup.js')}" type="text/javascript"></script>

		<%block name="scripts"></%block>

		<title>Boardless | <%block name="title">override this</%block></title>
	</head>
	<body>
		<%block name="header">
			<header class="header">
				<div class="wrapper clear">
					<a href="${request.route_url('games.list')}" class="logo">
						<img src="${request.static_url('boardless:static/img/logo-small.png')}" alt="Boardless" />
					</a>
					<menu class="header-menu">
						% if request.user:
							<%
								urls = [
									(request.route_url('games.list'),"Game list"),
									(request.route_url('games.joinable'),"Available game sessions"),
									(request.route_url('games.joined'), "Joined game sessions"),
									(request.route_url('rules.list'), "My rules")
								]
							%>
							%for url, name in urls:
								<a href="${url}" ${'class=active' if request.current_route_url() == url else ''}>${name}</a>
							%endfor
							<button class="btn btn-blue" id="feedback-modal-open">Feedback</button> 
						% endif
					</menu>
					% if request.user:
						<div class="user-block">
							<img src="${request.user.get_gravatar_link()}" class="user-block_avatar" alt="" />
							<p class="user-block_name">${request.user.nickname}</p>
							<a href="${request.route_url('auth.logout')}" class="user-block_logout icon icon-logout"></a>
							<a href="${request.route_url('profile.edit')}" class="user-block_settings icon icon-settings"></a>
							% if request.has_permission('admin'):
								<a href="${request.route_url('admin.main')}" class="user-block_settings icon icon-admin"></a>
							% endif
						</div>
					% endif
				</div>
			</header>
		</%block>

		${next.body()}

		<div id="js-popup" class="hidden popup">
			<div class="popup__bg" id="js-popup-background">
				## Pop up
				<div class="popup__wrapper">
					<a href="" class="popup__close icon icon-close"></a>
					<div class="popup__body" id="js-popup-container"></div>
				</div>
			</div>
		</div>

		<div class="feedback-modal-wrapper" id="feedback_modal">
			<div class="feedback-modal">
				<div class="feedback-modal-title">Send feedback</div>
				<div class="feedback-modal-content">
					<form id="feedback-form">
						<div class="control-group">
							<div class="controls">
								<label class="required" for="subject">Subject:</label>
								<input type="text" class="required" name="subject">
								<span class="error" for="subject"></span>
							</div>
						</div>
						<div class="control-group">
							<div class="controls">
								<label class="required" for="message_type">Type:</label>
								<select name="message_type">
									<option value="message" selected>Message</option>
									<option value="feature">Feature request</option>
									<option value="bug">Bug report</option>
									<span class="error" for="message_type"></span>
								</select>
							</div>
						</div>
						<div class="control-group">
							<div class="controls">
								<label class="required" for="message">Message:</label>
								<textarea class="required" name="message" rows="4" style="resize:none;"></textarea>
								<span class="error" for="message"></span>
							</div>
						</div>
					</form>
					
				</div>
				<div class="feedback-modal-footer">
					<button class="btn btn-blue" style="width: 20%" id="feedback-send">Send</button>
					<button class="btn btn-blue" id="feedback-modal-close">Close</button>
					
				</div>
			</div>
		</div>
	</body>
</html>