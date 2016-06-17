// Generated by CoffeeScript 1.9.1
(function() {
  $(function() {
    return board.Events = {};
  });

  board.EventDispatcher = (function() {
    function EventDispatcher() {}

    EventDispatcher.listen = function(event_name, clb) {
      if (board.Events[event_name] == null) {
        board.Events[event_name] = [];
      }
      return board.Events[event_name].push(clb);
    };

    EventDispatcher.emmit = function(event_name, params) {
      var clb, clbs, i, len, results;
      clbs = board.Events[event_name] || [];
      results = [];
      for (i = 0, len = clbs.length; i < len; i++) {
        clb = clbs[i];
        results.push(clb(params));
      }
      return results;
    };

    return EventDispatcher;

  })();

}).call(this);

//# sourceMappingURL=events.js.map
