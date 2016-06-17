<%inherit file="boardless:templates/base.mako"/>
<%namespace name="defs" file="boardless:templates/defs.mako"/>

<%block name="title">${page_title}</%block>
<%block name="header"></%block>

<div class="wrapper">
	<div class="auth">
		<img src="${request.static_url('boardless:static/img/logo-small-dark.png')}" />
		<script type="text/javascript">
			$(function () {
				$('#userid').focus();
			});
		</script>

		<form class="table-block w40 p-default" action="${request.route_path('auth.login')}" method="post">
			<input name="_login_submit" type="hidden" value="1">

			<div class="w100 p-default">
				<label class="" for="userid">Email</label>
				<input name="userid" type="text" id="userid" placeholder="" value="${data['userid']}">
			</div>
			<div class="w100 p-default">
				<label class="" for="password">Password</label>
				<input name="password" type="password" id="password" placeholder="" value="${data['password']}">
			</div>

			<div class="w100 p-default">
				<input type="submit" class="btn btn-blue" value="Sign in" />
			</div>

			%if auth_failed:
				<div class="alert alert-error">Incorrect email or password</div>
			%endif
		</form>

		<a href="${request.route_url('auth.restore_password_request')}">Forgot password</a>
	</div>
</div>