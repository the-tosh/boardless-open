# _*_ coding: utf-8 _*_

import os
import uuid
import time
import hashlib
import datetime

from pyramid_mailer import get_mailer
from pyramid.httpexceptions import HTTPFound

from sapyens.helpers import route_view_config
import sapyens.views
import sapyens.views.register
import sapyens.helpers


from boardless import constants
from boardless import helpers as h
from boardless import forms
from boardless.db import models
from boardless.libs.mail import messages

@sapyens.helpers.include_to_config()
class Logout (sapyens.views.LogoutView):
		route_name = 'auth.logout'
		route_path = '/auth/logout'
		redirect_route = 'games.list'

@sapyens.helpers.include_to_config()
class Login (sapyens.views.LoginView):
	route_name = 'auth.login'
	route_path = '/auth/login'
	renderer = 'boardless:templates/auth/login.mako'

	def _authenticate (self, data, request):
		request_params = h.update_request_params({'email': data['userid'], 'password': data['password']}, {})
		form = forms.AuthLogin(request_params)
		if not form.validate():
			return False

		user = models.User.query.filter_by(email = form.email.data).first()
		if not user or user.status != constants.UserStatus.ACTIVE:
			return False
		user.last_login = datetime.datetime.now()
		user.add()

		return True

@sapyens.helpers.include_to_config()
class RegisterView (sapyens.views.register.RegisterView):
	route_name = 'auth.registration'
	route_path = '/auth/registration'
	renderer = 'boardless:templates/auth/registration.mako'
	form_class = forms.AuthRegistration
	redirect_route = 'games.list'
	user_model = models.User
	page_title = 'Register'
	include_services = False
	include_email_form = True

	def __call__ (self, context, request):
		form = self.form_class(request.POST)
		form.invite.data = form.invite.data or request.GET.get('invite', '')
		result = {
			'form': form,
			'base_template': self.base_template,
			'page_title': self.page_title,
			'include_services': self.include_services,
			'include_email_form': self.include_email_form,
		}
		if request.method == 'POST' and form.validate():
			user = models.User()
			form.populate_obj(user)
			user.set_password(form.password.data)
			user.confirmation_hash = hashlib.md5(u'{}{}{}'.format(os.getpid(), time.time(), user.nickname.encode('utf-8'))).hexdigest()
			user.status = constants.UserStatus.NEW
			user.add()

			user.flush()

			invite_obj = models.BetaInvite.query.filter_by(hash = form.invite.data).first()
			invite_obj.user_id = user.id
			invite_obj.activation_time = datetime.datetime.utcnow()
			invite_obj.is_used = True
			invite_obj.add()

			mailer = get_mailer(request)
			mailer.send(messages.registration_confirmation(user))

			return HTTPFound(location = request.route_url('profile.confirm', confirmation_hash = user.confirmation_hash))

		return result

@route_view_config('/auth/restore_password_request', 'auth.restore_password_request', renderer = 'boardless:templates/auth/restore_password_request.mako')
def restore_password_request (request):
	form = forms.AuthRestorePasswordRequest(request.POST)

	message_sent = False
	if request.method == 'POST' and form.validate():
		user = models.User.query.filter_by(email = form.email.data).first()

		req = models.RestorePasswordRequest()
		req.user_id = user.id
		req.hash = hashlib.sha256(str(uuid.uuid4())).hexdigest()
		req.add()

		req.flush()

		models.RestorePasswordRequest.query.filter(
			models.RestorePasswordRequest.id != req.id,
			models.RestorePasswordRequest.user_id == user.id,
		).update({'is_used': True}, synchronize_session = False)

		mailer = get_mailer(request)
		mailer.send(messages.restore_password_request(user, req))

		message_sent = True

	return {'form': form, 'message_sent': message_sent}

@route_view_config('/auth/restore_password/{rhash:\w+}', 'auth.restore_password', renderer = 'boardless:templates/auth/restore_password.mako')
def restore_password (request):
	req_hash = request.matchdict['rhash']
	form_params = h.update_request_params(request.POST, {'req_hash': req_hash})
	form = forms.AuthRestorePassword(form_params)
	form.req_hash.query = models.RestorePasswordRequest.query.filter_by(is_used = False)

	if request.method == 'POST' and form.validate():
		restore_request = form.req_hash.data

		user = restore_request.user
		user.set_password(form.password.data)
		user.add()

		restore_request.is_used = True
		restore_request.add()

		return HTTPFound(location = request.route_url('auth.login'))

	return {'form': form}