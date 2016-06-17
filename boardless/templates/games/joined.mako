<%inherit file="boardless:templates/base.mako"/>

<%block name="title">Joined games</%block>

<div class="wrapper">
	<p class="navigation">
		<a href="${request.route_url('games.list')}">Home</a> <span>Joined games</span>
	</p>

	<table class="custom-table striped">
		<thead>
			<th>Game title</th>
			<th>Role</th>
			<th>Master's name</th>
			<th>Created (UTC)</th>
			<th></th>
		</thead>
		<tbody>
			% for session in sessions:
				<tr>
					<td><a href="${request.route_url('play', game_session_id = session.id)}">${session.rules.title}</a></td>
					<td>${session_roles[session.id]}</td>
					<td>${session.get_master().name}</td>
					<td>${h.datetime_client_format(session.ctime)}</td>
					<td>
						% if session_roles[session.id] == 'master':
							<a href="${request.route_url('games.close', game_session_id = session.id)}" class="btn btn-red">Close session</a>
						% endif
					</td>
				</tr>
			% endfor
		</tbody>
	</table>
</div>
