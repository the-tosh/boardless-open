$ ->
    board.Events = {}

class board.EventDispatcher
    @listen: (event_name, clb) ->
        if not board.Events[event_name]?
            board.Events[event_name] = []
        board.Events[event_name].push(clb)

    @emmit: (event_name, params) ->
        clbs = board.Events[event_name] or []
        for clb in clbs
            clb(params)