$ ->
    $('tr.js-clickable').bind 'click', (e) ->
        url = $(e.currentTarget).data 'url'
        window.location = url