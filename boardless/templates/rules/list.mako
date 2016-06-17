<%inherit file="boardless:templates/base.mako"/>
<%namespace name="defs" file="boardless:templates/defs.mako"/>

<%block name="title">My rules list</%block>

<%block name="scripts">
	<script type="text/javascript">
		$(function() {
			window.page = new RulesPage()
		});
	</script>
</%block>

<%block name="body">
	<div class="wrapper">

		<div class="row text-right m20">
			<div class="column w100">
				<button type="button" class="btn btn-blue" data-target="rules" data-state="close" data-opened-text="Close" data-closed-text="Invent your own game!" onclick="page.toggle_form(this);">Invent your own game!</button>
			</div>
		</div>

		<div class="row js-rules-form" style="display:none">
			<form action="${request.route_url('api.rules.create')}" method="POST" name="add_rules" data-submit_type="ajax">
				<div class="row w60">
					<div class="column w100">
						${defs.field_with_errors(form.title)}
					</div>
				</div>
				<div class="row w60">
					<div class="column w30">
						${defs.field_with_errors(form.max_players)}
					</div>
					<div class="column w70 text-right">
						<button type="submit" class="btn btn-blue" style="margin-top: 4%">Create!</button>
					</div>
				</div>
			</form>

			<hr />
		</div>

		<div class="row">
			<div class="column w100">
				<table class="custom-table">
					<tr>
						<td>
							<table class="custom-table striped">
								% for gr in game_rules:
									<tr>
										<td>
											% if gr.status == constants.GameRulesStatuses.IS_MODERATING:
												<p><a href="${request.route_url('rules.edit', rules_id = gr.id)}">${gr.title}</a></p>
											% else:
												<p><a href="${request.route_url('rules.view', rules_id = gr.id)}">${gr.title}</a></p>
											% endif
										</td>
									</tr>
								% endfor
							</table>
						</td>
					</tr>
				</table>
			</div>
		</div>
	</div>
</%block>