# _*_ encoding: utf-8 _*_

import time
import hashlib

from sapyens.helpers import route_view_config

from boardless.views.admin.main import ListView, EditView, NewView
from boardless.db import models
from boardless import helpers
from boardless import forms

@route_view_config('/admin/invite/list', 'admin.invite.list', renderer = '/admin/list.mako', request_method = 'GET', permission = 'admin')
class InviteList (ListView):
    QUERY = models.BetaInvite.query.order_by(models.BetaInvite.id.asc())
    FIELDS = ['id', 'hash', 'is_used', 'activation_time', 'user_id', 'ctime']
    EDIT_ROUTE = 'admin.invite.edit'
    NEW_ROUTE = 'admin.invite.new'

@route_view_config('/admin/invite/edit/{id:\d+}', 'admin.invite.edit', renderer = '/admin/edit.mako', permission = 'admin')
class InviteEdit (EditView):
    BINDED_FORM = forms.AdminInviteEdit

    def populate (self, form):
        invite = self.get_object()
        for k, v in form.data.items():
            if k == 'user_id':
                invite.user_id = v.id
            else:
                setattr(invite, k, v)
        invite.add()

    def get_object (self):
        invite_id = int(self.request.matchdict['id'])
        return models.BetaInvite.query.get(invite_id)

@route_view_config('/admin/invite/new', 'admin.invite.new', renderer = '/admin/new.mako', permission = 'admin')
class InviteNew (NewView):
    BINDED_FORM = forms.AdminInviteNew
    MODEL = models.BetaInvite
    EDIT_ROUTE = 'admin.invite.edit'

    def get_form_params (self):
        if 'hash' in self.request.POST:
            return self.request.POST

        _hash = hashlib.sha256(str(time.time())).hexdigest()
        form_params = helpers.update_request_params(self.request.POST, {'hash': _hash})

        return form_params