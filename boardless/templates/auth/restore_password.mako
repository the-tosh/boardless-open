<%inherit file="boardless:templates/base.mako"/>
<%namespace name="defs" file="boardless:templates/defs.mako"/>


<%block name="title">Restore password</%block>
<%block name="header"></%block>

<div class="wrapper">
	<div class="auth">
	<a href="/"><img src="${request.static_url('boardless:static/img/logo-small-dark.png')}" /></a>

		<form class="table-block w40 p-default" action="" method="post">
			<div class="w100 p-default">
				${defs.field_with_errors(form.password)}
			</div>
			<div class="w100 p-default">
				${defs.field_with_errors(form.password_confirm)}
			</div>

			<div class="w100 p-default">
				<button type="submit" class="btn btn-blue">Restore</button>
			</div>
		</form>

	</div>
</div>