window.normalize_form_parameters = (arr) ->
    r = {}
    for i in arr
        r[i.name] = i.value
    return r

class window.RulesPage
    constructor: (@rules_id, @skills_categories, @skills) ->
        @_counters = {}

        @renderer = ECT {root : '/static/js/templates/rules'}

        @forms = {
            rules: {
                main: ".js-rules-form"
            }
            skills: {
                main: ".js-skill-forms"
            }
            races: {
                main: ".js-race-form"
            }
            classes: {
                main: ".js-class-form"
            }
            items: {
                main: ".js-item-form"
            }
        }

        @templates = {
            skills_category: 'skills_category.ect'
            skill: 'skill.ect'
            race: 'race.ect'
            skill_select: 'skills_select.ect'
            character_class: 'character_class.ect'
            items_group: 'items_group.ect'
            item: 'item.ect'
            xp: 'character_level_row.ect'
        }

        @forms_clb = {
            "add_rules": @_create_rules_clb
            "edit_main": @_edit_main_clb
            "add_skills_category": @_add_skills_category_clb
            "add_skill": @_add_skill_clb
            "add_race": @_add_race_clb
            "add_class": @_add_class_clb
            "add_items_group": @_add_items_group_clb
            "add_item": @_add_item_clb
            "character_levels": @_character_levels_clb
        }


        @formula_controls = [] 

        for x in $(".js-level-formula-field")
            @formula_controls.push(new board.FormulaEditor(x.id))

        for s_id, s of @skills
            for f in @formula_controls
                f.add_keyword(s.title)

        @do_binds()


    get_counter: (entity) =>
        if not @counters?
            @_counters[entity] = 0
        else
            @_counters[entity] += 1

        return @_counters[entity]

    toggle_form: (el) =>
        $el = $(el)
        state = $el.attr('data-state')

        if state == 'close'
            $el.text($el.attr('data-opened-text'))
            $el.attr('data-state', 'open')
        else
            $el.text($el.attr('data-closed-text'))
            $el.attr('data-state', 'close')

        $(@forms[$el.attr('data-target')].main).slideToggle()

    process_errors: (form, errors_dict) =>
        # TODO: Errors description notifier
        for field of errors_dict
            # DISCLAIMER!
            # Each form keeps dict of the fields that have ID
            # But you can not use hyphen ("-" character) in ID
            # To solve this we decide to copy names of fields to their IDs,
            # but replace hyphens with double underscores.
            # And here we do the same to find appropriate field for error returned from the server.

            field_name = field.replace(/-/g, '__')
            $(form[field_name]).addClass('has-error')

    do_binds: =>
        $('#js-finalize-btn').bind 'click', (e) =>
            msg = 'Are you sure? After finalization you will not be able to edit the rules!'
            if confirm(msg)
                window.location = "/rules/finalize/#{@rules_id}"

        $("form[data-submit_type='ajax']").bind 'submit', (evt) =>
            evt.preventDefault()
            form = $(evt.currentTarget)[0]
            $form = $(form)
            url = form.action
            reset_on_success = $form.attr('data-reset-on-success')

            form_data = $form.serialize()
            if @rules_id?
                form_data += "&rules_id=#{@rules_id}"
            # Pre Validate form ?

            $.ajax
                type: 'POST'
                url: url
                data: form_data
                success: (response, textStatus, jqXHR) =>
                    if response.success
                        clb = @forms_clb[form.name]
                        if clb
                            clb(response.result)

                        if reset_on_success == 'true'
                            form.reset()

                    else if response.errors
                        @process_errors(form, response.errors)

                error: (jqXHR, textStatus, errorThrown) =>
                    response = jqXHR.responseJSON
                    if jqXHR.status == 422
                        @process_errors(form, response.errors)

    change_status: (el) =>
        $btn = $(el)
        $parent = $btn.parent().parent()
        child_id = $parent.attr('data-child_id')
        child_type = $parent.attr('data-child_type')
        is_disabled = parseInt ($parent.attr('data-is_disabled'))

        $.ajax
            type: 'POST'
            url: '/api/rules/child/change_status/',
            data: {
                id: child_id,
                disable: not is_disabled,
                child_type: child_type,
            }

            success: (data, textStatus, jqXHR) =>
                if data.success
                    $title = $parent.find('.js-child-title')

                    if is_disabled == 0
                        $parent.attr('data-is_disabled', '1')
                        $btn.html('Enable')
                        $btn.toggleClass('btn-blue')
                        $btn.toggleClass('btn-red')
                        $title.addClass('child-title-disabled')
                    else
                        $parent.attr('data-is_disabled', '0')
                        $btn.html('Disable')
                        $btn.toggleClass('btn-blue')
                        $btn.toggleClass('btn-red')
                        $title.removeClass('child-title-disabled')

                    if child_type == 'skill' # todo: use switch
                        for id, skill of @skills
                            if id == child_id
                                skill.is_disabled = not is_disabled
                                break

            error: (jqXHR, textStatus, errorThrown) ->
                console.log 'error', textStatus

    change_item_group_attr: (el) =>
        $btn = $(el)
        item_group_id = $btn.data('itemGroupId')
        attr_name = $btn.data('attrName')

        $.post '/api/rules/item_group/toggle_attribute',
            {
                rules_id: @rules_id,
                item_group: item_group_id,
                attr_name: attr_name,
            },
            ( (response) -> 
                if response.success
                    $btn.toggleClass('btn-grey btn-green')
            ),
        'json'

    _create_rules_clb: (rules) =>
        window.location = "/rules/edit/#{rules.id}"

    _edit_main_clb: (result) =>
        console.log "ok"

    _add_skills_category_clb: (s_category) =>
        $('#category').append("<option value='#{s_category.id}'>#{s_category.title}</option>")
        new_category = @renderer.render(@templates.skills_category, {skills_category: s_category})
        $(new_category).insertBefore($("tr.skills-category[data-skills_category_id='none']"))
        @skills_categories.push(s_category)
        @add_xp_column(s_category)

    _add_skill_clb: (skill) =>
        @skills[skill.id] = skill
        if skill.category_id == null
            skill.category_id = 'none'
        all_skills_selector = "tr.skill[data-skills_category_id='#{skill.category_id}']"
        amount_skills = $(all_skills_selector).length
        if amount_skills
            last_skill = $(all_skills_selector).last()
            $(@renderer.render(@templates.skill, {skill: skill})).insertAfter(last_skill)
        else
            $("tr.category-no-skills[data-skills_category_id='#{skill.category_id}']").remove()
            $(@renderer.render(@templates.skill, {skill: skill})).insertAfter($("tr.skills-category[data-skills_category_id='#{skill.category_id}']"))

        for f in @formula_controls
                f.add_keyword(skill.title)

    _add_race_clb: (race) =>
        amount_races = $("tr[data-child_type='race']").length
        skills = []
        for skill, value of race.skills
            skills.push("#{@skills[skill].title}: #{board.numeric_with_sign(value)}")
        content = @renderer.render(@templates.race, {race_counter: amount_races + 1, race: race, skills:skills.join(', ') or 'NO SKILL BONUS'})
        $(".races-table").append(content)
        $(".js-race-skills").empty()

    _add_class_clb: (character_class) =>
        amount_character_classes = $("tr[data-child_type='character_class']").length
        skills = []
        for skill, value of character_class.skills
            skills.push("#{@skills[skill].title}: #{board.numeric_with_sign(value)}")
        content = @renderer.render(@templates.character_class, {character_class_counter: amount_character_classes + 1, character_class: character_class, skills:skills.join(', ') or 'NO SKILL BONUS'})
        $(".character-classes-table").append(content)
        $(".js-character-class-skills").empty()

    _add_items_group_clb: (items_group) =>
        $("form[name=add_item] select[name=group_id]").append("<option value='#{items_group.id}'>#{items_group.title}</option>")
        new_items_group = @renderer.render(@templates.items_group, {ig: items_group})
        $("#items_table").append(new_items_group)

    _add_item_clb: (item) =>
        all_item_selector = "tr[data-items_group_id=#{item.group_id}][data-child_type=item]"
        amount_items = $(all_item_selector).length
        last_item_in_group = $(all_item_selector).last()
        skills = []
        for skill, value of item.skills
            skills.push("#{@skills[skill].title}: #{board.numeric_with_sign(value)}")
        content = @renderer.render(@templates.item, {number: amount_items + 1, 'item': item, 'skills': skills.join(', ') or 'NO SKILL BONUS'})
        if amount_items
            $(content).insertAfter($(last_item_in_group))
        else
            $(content).insertAfter($("tr[data-item_group_id=#{item.group_id}][data-child_type=items_group]"))
        $(".js-item-skills").empty()

    _character_levels_clb: (levels) =>
        console.log levels

    add_skill_to_obj: (entity, el) =>
        $target = $($(el).attr('data-target'))
        skills = @skills
        cnt = @get_counter(entity)
        content = @renderer.render(@templates.skill_select, {skills: skills, counter: cnt})
        $target.append(content)

    delete_skill_row: (el) =>
        $(el).closest('.row').remove()

    add_xp_column: (s_category) =>
        $("#character-levels-table tr.js-head").append("<th>Granted skills formula (#{s_category.title})</th>")
        _this = @
        $("#character-levels-table tr.js-level-row").each (i) ->
            formula_field_id = "#{i}_#{s_category.id}"
            $(this).append "<td>
                    <input type='hidden' name='skills_categories_formulas-#{i}-category_id' value='#{s_category.id}'>
                    <input type='hidden' name='skills_categories_formulas-#{i}-level' value='#{i+1}'>
                    <input id='#{formula_field_id}' class='js-level-formula-field' name='skills_categories_formulas-#{i}-formula' type='text' value='0' />
                </td>"
            f = new board.FormulaEditor(formula_field_id)
            for s_id, s of @skills
                f.add_keyword(s.title)
            _this.formula_controls.push(f)

    add_xp_rows: () =>
        level_rows = $("#character-levels-table tr.js-level-row")
        $level_rows = $(level_rows)
        new_level_rows_amount = parseInt($("#level-rows-to-add").val())
        for x in [1...new_level_rows_amount+1]
            $("#character-levels-table").append(@renderer.render(@templates.xp, {skills_categories: @skills_categories, level: $level_rows.length + x, rules_id: @rules_id}))

            for x in $("tr[data-level=#{$level_rows.length + x}] .js-level-formula-field")
                f = new board.FormulaEditor(x.id)
                for s_id, s of @skills
                    f.add_keyword(s.title)
                @formula_controls.push(f)
