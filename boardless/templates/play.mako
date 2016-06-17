<%inherit file="boardless:templates/base.mako"/>
<%namespace name="defs" file="boardless:templates/defs.mako"/>

<%block name="scripts">
	<script type="text/javascript">
		$(function() {
			var manager = new PlayManager(${game_session_id}, "${user_role}", ${cols_for_char_tbl | jsonify, n}, ${players | jsonify, n}, ${the_player_id}, ${skills | jsonify, n}, ${item_groups | jsonify, n}, ${skills_categories | jsonify, n}, ${items | jsonify, n}, ${character_token | jsonify, n}, ${dices | jsonify, n}, ${master.id}, ${token_tools | jsonify, n});
		})
	</script>
</%block>

<%block name="title"> Let's play ${rules.title}!</%block>

<div id="js-dices" class="dices-panel">
	<div id="js-dices-title" class="head">
		<h2>Dices</h2>
	</div>

	% if request.user.is_game_master(game_session_id):
		<div>
			% for dice in rules.dices:
				${defs.render_dice(dice, _class = "js-base-dice")}
			% endfor
		</div>

		<h3 class="middle-title">Chosen dices <span class="clickable" id="js-dices-reset">[reset]<span></h3>

		<div id="js-selected-dices"></div>

		<a id="js-roll-dice" href="javascript:void(0);" class="btn btn-blue">Roll</a>
	% endif

	<h3 class="middle-title">Results</h3>

	<div id="js-dice-results"></div>
</div>

<div id="playfield" class="playfield">
	<canvas id="canvas_draw" class="playfield-draw" height="500px" width="1000px"></canvas>
	<canvas id="canvas_grid" class="playfield-grid" height="500px" width="1000px"></canvas>
</div>

% if request.user.is_game_master(game_session_id):
	<table class="tools">
		<tr>
			<td>
				<strong>Drawing tools:</strong>
			</td>
			<td>
				<div id="js-toolbox-drawing-tools"></div>
			</td>
		</tr>

		<tr>
			<td>
				<strong>General tokens:</strong>
			</td>
			<td>
				<div id="js-toolbox-token-tools"></div>
			</td>
		</tr>

		<tr>
			<td>
				<strong>Player tokens:</strong>
			</td>
			<td>
				<div id="js-toolbox-players-avatars"></div>
			</td>
		</tr>

		<tr class="js-tool-related js-brush-related">
			<td>
				<strong>Colors:</strong>
			</td>
			<td>
				<input type="text" id="js-color-palette" />
			</td>
		</tr>

		<tr class="js-tool-related js-brush-related js-eraser-related">
			<td>
				<strong>Brush size:</strong>
			</td>
			<td>
				<div id="js-size-slider"></div>
			</td>
		</tr>
	</table>
% endif

% if master.user_id != request.user.id:
	<div class="m5">
		<strong>GAME MASTER:</strong>
		<span id="js-master-data" class="half-opaque">
			<img src="${master.user.get_gravatar_link(size = 32)}" />
			<strong>${master.name}</strong>
		</span>
	</div>

	<table id="the-player-dummy-tbl" class="player-inventory"></table>
	<table id="the-player-inventory-tbl" class="player-inventory"></table>

% endif

<div id="js-characters-sheet"></div>

<div class="hidden" id="js-active-tool-hidden-proxy-container"></div>
