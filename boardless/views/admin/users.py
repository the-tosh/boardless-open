# _*_ encoding: utf-8 _*_

from sapyens.helpers import route_view_config

from boardless.views.admin.main import ListView, EditView, NewView
from boardless.db import models
from boardless import forms

@route_view_config('/admin/users/list', 'admin.users.list', renderer = '/admin/list.mako', request_method = 'GET', permission = 'admin')
class UserList (ListView):
    QUERY = models.User.query.order_by(models.User.id.asc())
    FIELDS = ['id', 'email', 'nickname', 'status', 'group']
    EDIT_ROUTE = 'admin.users.edit'
    NEW_ROUTE = 'admin.users.new'

@route_view_config('/admin/users/edit/{id:\d+}', 'admin.users.edit', renderer = '/admin/edit.mako', permission = 'admin')
class UserEdit (EditView):
    BINDED_FORM = forms.AdminUserEdit

    def populate (self, form):
        user = self.get_object()
        form.populate_obj(user)
        user.add()

    def get_object (self):
        user_id = int(self.request.matchdict['id'])
        return models.User.query.get(user_id)

@route_view_config('/admin/users/new', 'admin.users.new', renderer = '/admin/new.mako', permission = 'admin')
class UserNew (NewView):
    BINDED_FORM = forms.AdminUserNew
    MODEL = models.User
    EDIT_ROUTE = 'admin.users.edit'

    def populate (self, form):
        obj = self.MODEL()
        form.populate_obj(obj)
        obj.set_password(form.password.data)
        obj.add()
        obj.flush()

        return obj