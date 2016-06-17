from sapyens.helpers import route_view_config

from boardless.views.admin.main import ListView, EditView, NewView
from boardless.db import models
from boardless import forms

@route_view_config('/admin/rules/list', 'admin.rules.list', renderer = '/admin/list.mako', request_method = 'GET', permission = 'admin')
class RulesList (ListView):
    QUERY = models.GameRules.query.order_by(models.GameRules.id.asc())
    FIELDS = ['id', 'title', 'creator_id', 'status', 'ctime']
    EDIT_ROUTE = 'admin.rules.edit'
    NEW_ROUTE = 'admin.rules.new'

@route_view_config('/admin/rules/edit/{id:\d+}', 'admin.rules.edit', renderer = '/admin/edit.mako', permission = 'admin')
class RulesEdit (EditView):
    BINDED_FORM = forms.AdminRulesEdit

    def populate (self, form):
        rules = self.get_object()
        for k, v in form.data.items():
            if k == 'creator_id':
                rules.creator_id = v.id
            else:
                setattr(rules, k, v)
        rules.add()

    def get_object (self):
        rules_id = int(self.request.matchdict['id'])
        return models.GameRules.query.get(rules_id)

@route_view_config('/admin/rules/new', 'admin.rules.new', renderer = '/admin/new.mako', permission = 'admin')
class RulesNew (NewView):
    BINDED_FORM = forms.AdminRulesNew
    MODEL = models.GameRules
    EDIT_ROUTE = 'admin.rules.edit'

    def populate (self, form):
        rules = self.MODEL()
        for k, v in form.data.items():
            if k == 'creator_id':
                rules.creator_id = v.id
            else:
                setattr(rules, k, v)

        rules.add()
        rules.flush()

        return rules