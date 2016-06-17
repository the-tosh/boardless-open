// Generated by CoffeeScript 1.9.1
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  board.FormulaEditor = (function() {
    function FormulaEditor(element_id) {
      this.make_choice = bind(this.make_choice, this);
      this.create_dropdown = bind(this.create_dropdown, this);
      this.add_keyword = bind(this.add_keyword, this);
      this.match = bind(this.match, this);
      this.do_binds = bind(this.do_binds, this);
      this.element_id = element_id;
      this.dropdown_id = "js-" + this.element_id + "-autocomplete-dropdown";
      this.keywords = ['level', 'self'];
      this.textarea = document.getElementById(element_id);
      this.$textarea = $(this.textarea);
      this.create_dropdown();
      this.dropdown = $("#" + this.dropdown_id);
      this.do_binds();
      this.current_word_obj = null;
    }

    FormulaEditor.prototype.do_binds = function() {
      this.$textarea.bind("keydown", function(event) {
        if (event.keyCode === 10 || event.keyCode === 13) {
          return event.preventDefault();
        }
      });
      return this.$textarea.bind("keyup paste copy cut mouseup", (function(_this) {
        return function(event) {
          return _this.match();
        };
      })(this));
    };

    FormulaEditor.prototype.match = function() {
      var caret_position, i, keyword, len, matches, parsed_names, ref, start_offset, text, word, word_obj;
      this.dropdown.empty();
      caret_position = this.get_caret_position();
      text = $.trim(this.textarea.value);
      if (text) {
        parsed_names = PEG.parse(text, {
          'startRule': 'Node'
        });
        for (start_offset in parsed_names) {
          word_obj = parsed_names[start_offset];
          if (start_offset <= caret_position && word_obj.end_offset >= caret_position) {
            this.current_word_obj = word_obj;
            break;
          }
        }
      }
      if (this.current_word_obj == null) {
        return;
      }
      word = this.current_word_obj.name;
      matches = [];
      if (word.length >= 2) {
        ref = this.keywords;
        for (i = 0, len = ref.length; i < len; i++) {
          keyword = ref[i];
          if (keyword.indexOf(word) !== -1) {
            if (matches.indexOf(keyword) === -1) {
              matches.push(keyword);
              $('<p><div class="choice">' + keyword + '</div></p>').appendTo("#" + this.dropdown_id);
              this.dropdown.show();
            }
          }
        }
      }
      return $("#" + this.dropdown_id + " .choice").bind('click', (function(_this) {
        return function(e) {
          _this.make_choice($(e.currentTarget).html());
          return _this.dropdown.hide();
        };
      })(this));
    };

    FormulaEditor.prototype.get_caret_position = function() {
      var position, selection;
      position = 0;
      if (document.selection) {
        this.textarea.focus();
        selection = document.selection.createRange();
        selection.moveStart('character', -this.textarea.value.length);
        position = selection.text.length;
      } else if (this.textarea.selectionStart || this.textarea.selectionStart === '0') {
        position = this.textarea.selectionStart;
      }
      return position;
    };

    FormulaEditor.prototype.add_keyword = function(keyword) {
      return this.keywords.push(keyword);
    };

    FormulaEditor.prototype.create_dropdown = function() {
      return $('<div />', {
        id: this.dropdown_id,
        style: "display: none; position: absolute; z-index: 10; background: white; padding: 5px;"
      }).appendTo(this.$textarea.parent());
    };

    FormulaEditor.prototype.make_choice = function(choice) {
      var new_string, old_string;
      if (this.current_word_obj == null) {
        return;
      }
      old_string = this.textarea.value;
      new_string = this.current_word_obj.start_offset ? old_string.slice(0, +(this.current_word_obj.start_offset - 1) + 1 || 9e9) : "";
      new_string = new_string + "\"" + choice + "\"" + old_string.slice(this.current_word_obj.end_offset);
      this.textarea.value = new_string;
      this.current_word_obj = null;
      return this.dropdown.empty();
    };

    return FormulaEditor;

  })();

}).call(this);

//# sourceMappingURL=formula.js.map