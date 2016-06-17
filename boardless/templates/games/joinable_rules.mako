<%inherit file="boardless:templates/base.mako"/>

<%block name="title">Joinable games</%block>

<div class="wrapper">
	<p class="navigation">
		<a href="${request.route_url('games.list')}">Home</a> <a href="${request.route_url('games.joinable')}">Rules available to join</a> <span>Joinable games for ${sessions[0].rules.title}</span>
	</p>

	<table class="custom-table striped">
		<thead>
			<th>#</th>
			<th>Game title</th>
			<th>Master's name</th>
			<th>Created (UTC)</th>
			<th>Join</th>
		</thead>
		<tbody>
			% for i, session in enumerate(sessions):
				<tr>
					<td>${i + 1}</td>
					<td>${session.rules.title}</td>
					<td>${session.get_master().name}</td>
					<td>${h.datetime_client_format(session.ctime)}</td>
					<td><a href="${request.route_url('games.join', game_session_id = session.id)}" class="btn btn-blue">Join</a></td>
				</tr>
			% endfor
		</tbody>
	</table>
</div>