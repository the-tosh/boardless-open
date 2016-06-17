<%inherit file="boardless:templates/base.mako"/>
<%namespace name="defs" file="boardless:templates/defs.mako"/>

<%block name="title"> Create game rules </%block>

<article class="main-block">
	<div class="wrapper">
		<p class="navigation">
			<a href="${request.route_url('rules.list')}">Home</a> <span>Create rules</span>
		</p>

		<form action="${request.route_url('rules.create')}" method="POST">
			<div class="row">
				<div class="column w70">
					${defs.field_with_errors(form.title)}
				</div>
				<div class="column w20">
					${defs.field_with_errors(form.max_players)}
				</div>
			</div>
			<div class="row w100 text-center">
				<div class="column w100">
					<button type="submit" class="btn btn-blue">Create</button>
				</div>
			</div>
		</form>
	</div>
</article>