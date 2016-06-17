// Generated by CoffeeScript 1.9.1

/* Name Spaces */

(function() {
  var open_form,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.board = {};

  window.board.ECT = ECT();

  board.static_url = function(path) {
    return window.location.origin + "/static/" + path;
  };

  board.numeric_with_sign = function(num) {
    if (num > 0) {
      return "+" + num;
    } else if (num < 0) {
      return "" + num;
    }
    return "0";
  };

  board.Popup = (function() {
    function Popup() {}

    Popup.show = function() {
      return $('#js-popup').removeClass('hidden');
    };

    Popup.hide = function() {
      return $('#js-popup').addClass('hidden');
    };

    Popup.render_template = function(tpl_path, context, callback) {
      $('#js-popup-container').html(board.ECT.render("/static/js/templates/popup" + tpl_path, context));
      board.Popup.show();
      $('.popup__close').bind('click', (function(_this) {
        return function(e) {
          e.preventDefault();
          _this.hide();
        };
      })(this));
      if (callback != null) {
        return callback();
      }
    };

    Popup.clean = function() {
      return $('#js-popup-container').empty();
    };

    return Popup;

  })();

  board.Feedback = (function() {
    function Feedback() {
      this.do_binds = bind(this.do_binds, this);
      this.close = bind(this.close, this);
      this.open = bind(this.open, this);
      this.$elem = $('#feedback_modal');
      this.do_binds();
    }

    Feedback.prototype.open = function() {
      return this.$elem.fadeIn();
    };

    Feedback.prototype.close = function() {
      return this.$elem.fadeOut();
    };

    Feedback.prototype.do_binds = function() {
      $('#feedback-modal-open').bind('click', (function(_this) {
        return function(e) {
          e.preventDefault();
          return _this.open();
        };
      })(this));
      $('#feedback-modal-close').bind('click', (function(_this) {
        return function(e) {
          e.preventDefault();
          return _this.close();
        };
      })(this));
      return $('#feedback-send').bind('click', (function(_this) {
        return function(e) {
          var $form, data, el, j, len, ref;
          $form = $('#feedback-form');
          data = {
            'page': document.URL
          };
          ref = $form.serializeArray();
          for (j = 0, len = ref.length; j < len; j++) {
            el = ref[j];
            data[el.name] = el.value;
          }
          return $.ajax({
            type: 'POST',
            url: '/feedback/',
            data: data,
            success: function(data, textStatus, jqXHR) {
              _this.$elem.find('.error').empty();
              $('#feedback-form').trigger('reset');
              _this.close();
              return runNoty("Feedback was sent");
            },
            error: function(jqXHR, textStatus, errorThrown) {
              var $error, errors, field_errors, field_name, response, results;
              response = jqXHR.responseJSON;
              if (jqXHR.status === 422) {
                errors = response.errors;
                results = [];
                for (field_name in errors) {
                  field_errors = errors[field_name];
                  $error = _this.$elem.find(".error[for=" + field_name + "]");
                  results.push($error.html(field_errors[0]));
                }
                return results;
              }
            }
          });
        };
      })(this));
    };

    return Feedback;

  })();

  board.runAjax = function(type, url, data, _method, __this) {
    if ((url != null) && (data != null)) {
      return $.ajax({
        type: type,
        url: url,
        data: data,
        success: function(data, textStatus, jqXHR) {
          if (_method != null) {
            _method.call(__this, {
              type: "success",
              data: data
            });
          }
        },
        error: function(jqXHR, textStatus, errorThrown) {
          _method.call(__this, {
            type: "error",
            data: errorThrown
          });
        }
      });
    } else {
      return console.log("No required arguments");
    }
  };

  window.runNoty = function(text, type) {
    if (type == null) {
      type = "information";
    }
    noty({
      text: text,
      type: type,
      dismissQueue: true,
      layout: 'topRight',
      theme: 'defaultTheme',
      timeout: 10000
    });
  };

  window.str_to_fun = function(functionName) {
    var arr, el, fun, i, j, len;
    arr = functionName.split(".");
    for (i = j = 0, len = arr.length; j < len; i = ++j) {
      el = arr[i];
      if (i === 0) {
        fun = window[el];
      } else {
        fun = fun[el];
      }
    }
    return fun;
  };

  window.add_hash = function(data) {
    window.location.hash = "message=" + data;
    return window.location.reload();
  };

  window.cache_observer = function() {
    var hash;
    hash = window.location.hash;
    if (hash !== "") {
      if (hash.indexOf("message") !== -1) {
        runNoty(hash.split("=")[1]);
        return window.location.hash = "";
      }
    }
  };

  open_form = function() {
    return $(".opener-btn").on("click", function(e) {
      var form, target_btn;
      e.preventDefault();
      target_btn = $(e.target);
      form = target_btn.parent().parent().find("form");
      form.removeClass("hidden");
      target_btn.hide();
      form.find(".cansel-btn").one("click", function(e) {
        var btn;
        e.preventDefault();
        btn = $(e.target);
        btn.parent().parent("form").addClass("hidden");
        btn.parent().parent().parent().find("a.opener-btn").show();
      });
    });
  };


  /*    Definitions */

  $.noty.layouts.topRight = {
    name: 'topRight',
    container: {
      object: '<ul id="noty_topRight_layout_container" />',
      selector: 'ul#noty_topRight_layout_container',
      style: function() {
        return $(this).css({
          top: 20,
          right: 20,
          position: 'fixed',
          width: '310px',
          height: 'auto',
          margin: 0,
          padding: 0,
          listStyleType: 'none',
          zIndex: 10000000
        });
      }
    },
    parent: {
      object: '<li />',
      selector: 'li',
      css: {}
    },
    css: {
      display: 'none',
      width: '310px'
    },
    addClass: ''
  };


  /*    On document is ready() */

  $(function() {
    var items;
    cache_observer();
    open_form();
    if (document.getElementsByClassName('stuff').length > 0) {
      items = new board.Items(document.getElementsByClassName('stuff')[0]);
    }
    return new board.Feedback();
  });

}).call(this);

//# sourceMappingURL=main.js.map