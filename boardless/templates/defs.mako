<%def name="field_with_errors(field, need_label = True, **kwargs)">
	% if need_label:
		% if "required" in field.flags:
			${field.label (class_ = "required")}
		% else:
			${field.label}
		% endif
	% endif

	% if field.errors:
		${field(class_='has_error ' + ("required" if "required" in field.flags else "") + kwargs.pop('class_', ''), **kwargs)}
		<span class="error">${','.join(field.errors)}</span>
	% else:
		% if "required" in field.flags:
			${field(class_ = kwargs.pop('class_', "") + "required", **kwargs)}
		% else:
			${field(**kwargs)}
		% endif
	% endif
</%def>

<%def name="checkbox_with_errors(field, need_label = True, **kwargs)">
	% if field.errors:
		${field(class_='has_error ' + ("required" if "required" in field.flags else "") + kwargs.pop('class_', ''), **kwargs)}
		% if need_label:
			% if "required" in field.flags:
				${field.label (class_ = "required")}
			% else:
				${field.label}
			% endif
		% endif
		<span class="error">${','.join(field.errors)}</span>
	% else:
		% if "required" in field.flags:
			${field(class_ = kwargs.pop('class_', "") + "required", **kwargs)}
		% else:
			${field(**kwargs)}
		% endif

		% if need_label:
			% if "required" in field.flags:
				${field.label (class_ = "required")}
			% else:
				${field.label}
			% endif
		% endif
	% endif
</%def>

<%def name="render_dice(dice, value = None, _class = '')">
	<div class="clickable dice-block ${_class}" dice-id="${dice.id}">
		% if value is not None:
			<div class="dice-value ${dice.name}">
				<strong>${value}</strong>
			</div>
		% endif
		<img src="${dice.get_image_url(request.static_url('boardless:static/'))}" />
		<p><strong>${dice.name}</strong></p>
	</div>
</%def>