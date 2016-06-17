<%inherit file="/base.mako" />
<%namespace name="defs" file="boardless:templates/defs.mako"/>

<%block name="title">Admin</%block>

<%block name="scripts">
    <script src="${request.static_url('boardless:static/js/compiled/admin.js')}" type="text/javascript"></script>
</%block>

<%
    pages = ['USERS', 'RULES', 'INVITES']

    page_urls = {
        'USERS': request.route_url('admin.users.list'),
        'RULES': request.route_url('admin.rules.list'),
        'INVITES': request.route_url('admin.invite.list'),
    }
%>

<div class="left-menu-wrapper">
    <table class="admin-left-menu striped">
        <thead>
            <tr>
                <td>
                    <strong>MENU</strong>
                </td>
            </tr>
        </thead>

        <tbody>
            % for page_name in pages:
                <tr class="js-clickable" data-url="${page_urls[page_name]}">
                    <td>
                        ${page_name}
                    </td>
                </tr>
            % endfor
        </tbody>
    </table>
</div>

<div class="admin-page-wrapper">
   ${next.body()}
</div>