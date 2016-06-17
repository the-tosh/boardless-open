// Generated by CoffeeScript 1.9.1
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.WSClient = (function() {
    function WSClient(token) {
      this.token = token;
      this.register_action = bind(this.register_action, this);
      this._send = bind(this._send, this);
      this.request = bind(this.request, this);
      this.receive_handler = bind(this.receive_handler, this);
      this.on_open = bind(this.on_open, this);
      this.create_connection = bind(this.create_connection, this);
      this.authenticate = bind(this.authenticate, this);
      this.url = "ws://" + window.board.WS_HOST + ":" + window.board.WS_PORT + "/playground";
      this.request_id = null;
      this.callbacks = {};
      this.actions = {};
      this.create_connection();
    }

    WSClient.prototype.authenticate = function() {
      var data;
      data = {
        'action': 'Authenticate',
        'params': {
          'token': this.token
        }
      };
      return this._send(data, this.request_id);
    };

    WSClient.prototype.create_connection = function() {
      var settings;
      settings = {
        'timeoutInterval': 1000,
        'reconnectInterval': 3000,
        'reconnectDecay': 1.0,
        'debug': false
      };
      this.connection = new ReconnectingWebSocket(this.url, null, settings);
      this.connection.onopen = this.on_open;
      this.connection.onerror = this.error_handler;
      this.connection.onmessage = this.receive_handler;
      this.connection.onclose = this.on_close;
      return window.onbeforeunload = (function(_this) {
        return function() {
          return _this.connection.close();
        };
      })(this);
    };

    WSClient.prototype.on_open = function(event) {
      console.log('Connection established');
      return this.authenticate();
    };

    WSClient.prototype.on_close = function(event) {
      return console.log('Connection was closed');
    };

    WSClient.prototype.error_handler = function(error) {
      console.log(error);
      return console.log("WebSocket Error!", error);
    };

    WSClient.prototype.receive_handler = function(event) {
      var clb, data, i, len, ref;
      data = JSON.parse(event.data);
      console.log("Data was received: ", data);
      if (data.request_id) {
        if (this.callbacks[data.request_id] != null) {
          this.callbacks[data.request_id](data);
          this.callbacks[data.request_id] = null;
        }
      }
      if (data.call_action) {
        if (this.actions[data.call_action] != null) {
          ref = this.actions[data.call_action];
          for (i = 0, len = ref.length; i < len; i++) {
            clb = ref[i];
            clb(data.params);
          }
        }
      }
      if (data.is_authorized) {
        return this.request_id = 1;
      }
    };

    WSClient.prototype.request = function(action, params, clb) {
      var data, tmp_request_id;
      console.log('Request:', action, params, clb);
      if (this.request_id) {
        tmp_request_id = this.request_id += 1;
        if (clb) {
          this.callbacks[tmp_request_id] = clb;
        }
        data = {
          'action': action,
          'params': params
        };
        return this._send(data, tmp_request_id);
      } else {
        console.log('Waiting for auth');
        return setTimeout((function(_this) {
          return function() {
            return _this.request(action, params, clb);
          };
        })(this), 1500);
      }
    };

    WSClient.prototype._send = function(data, request_id) {
      if (request_id != null) {
        data['params']['request_id'] = request_id;
      }
      return this.connection.send(JSON.stringify(data));
    };

    WSClient.prototype.register_action = function(name, clb) {
      console.log("Register action for name " + name);
      if (this.actions[name] == null) {
        this.actions[name] = [];
      }
      return this.actions[name].push(clb);
    };

    return WSClient;

  })();

  window.DummyClient = (function() {
    function DummyClient() {
      this.request = bind(this.request, this);
    }

    DummyClient.prototype.request = function(action, params, clb) {};

    return DummyClient;

  })();

}).call(this);

//# sourceMappingURL=ws_client.js.map
