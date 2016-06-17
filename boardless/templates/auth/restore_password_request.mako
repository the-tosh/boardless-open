<%inherit file="boardless:templates/base.mako"/>
<%namespace name="defs" file="boardless:templates/defs.mako"/>


<%block name="title">Restore password request</%block>
<%block name="header"></%block>

<div class="wrapper">
	<div class="auth">
		<a href="/"><img src="${request.static_url('boardless:static/img/logo-small-dark.png')}" /></a>

		% if message_sent:
			<div class="w100 p-default">
				<span class="success">Message with instructions has been sent. Please, check your email.</span>
			</div>
		% else:
			<form class="table-block w40 p-default" action="" method="post">
				<div class="w100 p-default">
					${defs.field_with_errors(form.email)}
				</div>

				<div class="w100 p-default">
					<button type="submit" class="btn btn-blue">Restore</button>
				</div>
			</form>
		% endif
	</div>
</div>