<%inherit file="boardless:templates/base.mako"/>
<%namespace name="defs" file="boardless:templates/defs.mako"/>

<%block name="title">Confirmation</%block>

<%block name="body">

	<div class="wrapper">
		% if success_action == 'change_password':
			<span class="error">Password has been changed</span>
		% endif

		<div class="block-title">
			Change password
		</div>

		<form method="POST">
			<div class="row form-control">
				<div class="column w50">
					${defs.field_with_errors(password_form.password_old)}
				</div>
			</div>

			<div class="row form-control">
				<div class="column w50">
					${defs.field_with_errors(password_form.password)}
				</div>
			</div>

			<div class="row form-control">
				<div class="column w50">
					${defs.field_with_errors(password_form.password_confirm)}
				</div>
			</div>

			<input type="hidden" name="change_password" value="1" />

			<div class="row form-control">
				<div class="column w50">
					<button type="submit" class="btn btn-blue">Change</button>
				</div>
			</div>
		</form>
	</div>

</%block>
