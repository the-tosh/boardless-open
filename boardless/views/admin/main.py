# _*_ encoding: utf-8 _*_

# import datetime
import math

from pyramid.httpexceptions import HTTPFound

from sapyens.helpers import route_view_config

from boardless import helpers
from boardless import constants
from boardless.db import models

class ListView (object):
    QUERY = None # Should be implemented in proper view
    FIELDS = None # Should be implemented in proper view
    EDIT_ROUTE = None # Should be implemented in proper view
    NEW_ROUTE = None # Should be implemented in proper view
    LIMIT = 50

    def __init__ (self, root_factory, request):
        self.root_factory = root_factory
        self.request = request

    def __call__ (self):
        # TODO: Filters and ordering
        page = int(self.request.GET.get('page', 1))
        offset = (page - 1) * self.LIMIT

        pages_num = int(math.ceil(self.QUERY.count() / float(self.LIMIT)))
        objects = self.QUERY.offset(offset).limit(self.LIMIT)

        return {'objects': objects, 'object_fields': self.FIELDS, 'pages_num': pages_num, 'edit_route': self.EDIT_ROUTE, 'new_route': self.NEW_ROUTE}

class EditView (object):
    BINDED_FORM = None # Should be implemented in proper view

    def __init__ (self, root_factory, request):
        self.root_factory = root_factory
        self.request = request

    def __call__ (self):
        obj = self.get_object()
        form = self.BINDED_FORM(obj = obj)

        if self.request.method == 'POST':
            form_params = self.get_form_params()
            form = self.BINDED_FORM(form_params)
            if form.validate():
                self.populate(form)

        return {'form': form}

    def get_form_params (self):
        obj_id = self.request.matchdict['id']
        form_params = helpers.update_request_params(self.request.POST, {'id': obj_id})

        return form_params

    def populate (self, form):
        raise NotImplementedError("Should be implemented in child classes")

    def get_object (self, form):
        raise NotImplementedError("Should be implemented in child classes")

class NewView (object):
    BINDED_FORM = None # Should be implemented in proper view
    MODEL = None # Should be implemented in proper view

    def __init__ (self, root_factory, request):
        self.root_factory = root_factory
        self.request = request

    def __call__ (self):
        form_params = self.get_form_params()
        form = self.BINDED_FORM(form_params)

        if self.request.method == 'POST':
            if form.validate():
                obj = self.populate(form)
                print obj.id
                return HTTPFound(location = self.request.route_url(self.EDIT_ROUTE, id = obj.id))

        return {'form': form}

    def get_form_params (self):
        return self.request.POST

    def populate (self, form):
        obj = self.MODEL()
        form.populate_obj(obj)
        obj.add()
        obj.flush()

        return obj

@route_view_config('/admin', 'admin.main', renderer = '/admin/main.mako', request_method = 'GET', permission = 'admin')
def main (request):
    return {
        'users_total': models.User.query.count(),
        'users_confirmed': models.User.query.filter(models.User.group != 'unconfirmed').count(),

        'invites_total': models.BetaInvite.query.count(),
        'invites_used': models.BetaInvite.query.filter(models.BetaInvite.user_id != None).count(),

        'rules_total': models.GameRules.query.count(),
        'rules_active': models.GameRules.query.filter(models.GameRules.status == constants.GameRulesStatuses.AVAILABLE).count()
    }