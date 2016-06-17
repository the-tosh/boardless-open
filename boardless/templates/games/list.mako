<%inherit file="boardless:templates/base.mako"/>

<%block name="title">Games list</%block>


<div class="wrapper">
	<table class="custom-table striped">
		<thead>
			<th>#</th>
			<th>Title</th>
			<th>View</th>
			<th>Play</th>
		</thead>
		<tbody>
			% for i, rules in enumerate(rules_list):
				<tr>
					<td>${i + 1}</td>
					<td>${rules.title}</td>
					<td><a class="btn btn-blue" href="${request.route_url('rules.view', rules_id = rules.id)}">View details</a></td>
					<td><a class="btn btn-blue" href="${request.route_url('games.create', rules_id = rules.id)}">Start session!</a></td>
				</tr>
			% endfor
		</tbody>
	</table>
</div>