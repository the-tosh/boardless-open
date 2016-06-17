<%inherit file="/admin/admin_base.mako" />
<%namespace name="defs" file="boardless:templates/defs.mako"/>

<form action="${request.current_route_url()}" method="POST">
    % for group_name, fields_list in form.FIELDS_ORDER:
        <h1>${group_name}</h1>
        % for field_name in fields_list:
            <% field = getattr(form, field_name) %>
            % if hasattr(field, 'widget') and hasattr(field.widget, 'input_type') and field.widget.input_type == 'checkbox':
                ${defs.checkbox_with_errors(field)}
                ## TODO: DIRTY HACK. FIX IT
                <br/>
                <br/>
            % else:
                ${defs.field_with_errors(field)}
            % endif
        % endfor
    % endfor

    <input type="submit" class="btn btn-blue" value="Save" />
</form>