<%inherit file="/admin/admin_base.mako" />

<table class="custom-table">
    <tr><td colspan="2"><strong>USERS</strong></td></tr>
    <tr>
        <td><strong>Total:</strong></td>
        <td>${users_total}</td>
    </tr>
    <tr>
        <td><strong>Confirmed:</strong></td>
        <td>${users_confirmed}</td>
    </tr>

    <tr><td colspan="2"><strong>RULES</strong></td></tr>
    <tr>
        <td><strong>Total:</strong></td>
        <td>${rules_total}</td>
    </tr>
    <tr>
        <td><strong>Active:</strong></td>
        <td>${rules_active}</td>
    </tr>

    <tr><td colspan="2"><strong>INVITES</strong></td></tr>
    <tr>
        <td><strong>Total:</strong></td>
        <td>${invites_total}</td>
    </tr>
    <tr>
        <td><strong>Used:</strong></td>
        <td>${invites_used}</td>
    </tr>
</table>