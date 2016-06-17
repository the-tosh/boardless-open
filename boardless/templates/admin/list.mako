<%inherit file="/admin/admin_base.mako" />
<%namespace name="defs" file="boardless:templates/defs.mako"/>

<%block name="objects_list">
    <table class="striped admin-list">
        <thead>
            <tr>
                % for field_name in object_fields:
                    <td><strong>${field_name}</strong></td>
                % endfor
            </tr>
        </thead>
        <tbody>
            % for obj in objects:
                <tr class="js-clickable" data-url="${request.route_url(edit_route, id = obj.id)}">
                    % for field_name in object_fields:
                        <td>${getattr(obj, field_name)}</td>
                    % endfor
                </tr>
            % endfor
        </tbody>
    </table>
</%block>

## Pagination
<%block name="pagination">
    <% current_page = int(request.GET.get('page', 1)) %>
    <div style="text-align: center">
        <a href="${request.route_url(new_route)}" class="btn btn-blue">NEW</a>
        <strong>PAGES:</strong>
        % for page in range(1, pages_num + 1):
            % if page == current_page:
                <span>${page}</span>
            % else:
                <span><a href="${request.current_route_path(_query = {'page': page})}">${page}</a></span>
            % endif
        % endfor
    </div>
</%block>