import pyramid.security

from sapyens.helpers import route_view_config

from boardless import helpers as h
from boardless import forms
from boardless.db import models
from boardless import constants

@route_view_config('/profile/confirm/{confirmation_hash:.+}', 'profile.confirm', renderer = '/profile/confirm.mako')
def confirm (request):
	conf_hash = request.matchdict['confirmation_hash']
	user = models.User.query.filter_by(confirmation_hash = conf_hash).first()
	if not user or user.status != constants.UserStatus.NEW:
		return {'is_valid_hash': False}

	user.status = constants.UserStatus.ACTIVE
	user.group = "confirmed"
	user.add()

	request.response.headerlist.extend(pyramid.security.remember(request, user.email))

	return {'is_valid_hash': True}

@route_view_config('/profile', 'profile.edit', renderer = '/profile/edit.mako', permission = 'view')
def edit (request):
	user = request.user
	password_form = forms.ProfilePasswordChange()
	action = None

	if 'change_password' in request.POST:
		form_data = h.update_request_params({'email': user.email}, request.POST)
		password_form = forms.ProfilePasswordChange(form_data)
		if password_form.validate():
			user.set_password(password_form.password.data)
			user.add()
			action = 'change_password'

	return {
		'password_form': password_form,
		'success_action': action,
	}
