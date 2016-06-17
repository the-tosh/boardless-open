# _*_ coding: utf-8 _*_

import json
import datetime

from decimal import Decimal

from pyramid.security import forget, authenticated_userid
from webob.multidict import MultiDict

from boardless.db import models

def jsonify (data):
	return json.dumps(data)

def numeric_with_sign (num):
	if num > 0:
		return "+{}".format(num)
	elif num < 0:
		return "{}".format(num)
	return "0"

def update_request_params (request_params, update_dict = None):
	result_data = MultiDict(request_params)
	result_data.extend(update_dict or {})

	return result_data

def ignore_request_params_fields (request_params):
	result_data = MultiDict()

	for name, value in request_params.items():
		if value != "IGNORE-THIS-FIELD":
			result_data.add(name, value)

	return result_data

def generic_error (msg):
	return {'errors': {'generic_error': [msg]}}

def datetime_client_format (dt):
	return datetime.datetime.strftime(dt, '%d.%m.%Y %H:%M:%S')

def decimal_json_encoder (object, request):
	return '{0}'.format(object.quantize(Decimal('0.00001')))

def get_user (request):
	user_email = authenticated_userid(request)
	user = models.User.query.filter_by(email = user_email).first()

	if not user:
		request.response.headerlist.extend(forget(request))

	return user