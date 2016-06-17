<%inherit file="boardless:templates/base.mako"/>

<%block name="title">Joinable games</%block>

<div class="wrapper">
	<p class="navigation">
		<a href="${request.route_url('games.list')}">Home</a> <span>Rules available to join</span>
	</p>

	<table class="custom-table striped">
		<thead>
			<th>#</th>
			<th>Rules name</th>
			<th>Running games</th>
			<th></th>
		</thead>
		<tbody>
			% for i, rs in enumerate(rules_sessions):
				<tr>
					<td>${i + 1}</td>
					<td>${rs.title}</td>
					<td>${rs.sessions_num}</td>
					<td><a href="${request.route_url('games.joinable_rules', rules_id = rs.id)}" class="btn btn-blue">Choose</a></td>
				</tr>
			% endfor
		</tbody>
	</table>
</div>