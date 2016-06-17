<%inherit file="boardless:templates/base.mako"/>

<%block name="scripts">
	<meta http-equiv="refresh" content="5;url=${request.route_url('games.list')}">
</%block>

<%block name="title">Confirmation</%block>

<%block name="body">

<div class="wrapper">
	% if is_valid_hash:
		Учетная запись активирована!
	% else:
		Учетная запись не найдена!
	% endif
</div>

</%block>
