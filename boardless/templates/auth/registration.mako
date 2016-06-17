<%inherit file="boardless:templates/base.mako"/>
<%namespace name="defs" file="boardless:templates/defs.mako"/>


<%block name="title">Registration</%block>
<%block name="header"></%block>

<div class="wrapper">
	<div class="auth">
		<img src="${request.static_url('boardless:static/img/logo-small-dark.png')}" />

		<form class="table-block w40 p-default" action="" method="post">
			<div class="w100 p-default">
				${defs.field_with_errors(form.email)}
			</div>
			<div class="w100 p-default">
				${defs.field_with_errors(form.nickname)}
			</div>
			<div class="w100 p-default">
				${defs.field_with_errors(form.password)}
			</div>
			<div class="w100 p-default">
				${defs.field_with_errors(form.password_confirm)}
			</div>
			
			<div class="w100 p-default">
				${defs.field_with_errors(form.invite)}
			</div>

			<div class="w100 p-default">
				<input type="submit" class="btn btn-blue" value="Registration" />
			</div>
		</form>
	</div>
</div>