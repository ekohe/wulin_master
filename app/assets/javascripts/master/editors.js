(function($) {

  ///////////////////////////////////////////////////////////////////////////
  // BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  function BaseEditor(args) {
    this.args = args;
    this.column = args.column;
  }

  BaseEditor.prototype = {
    destroy: function() {
      if (this.wrapper) {
        this.wrapper.remove();
      } else {
        this.element.remove();
      }
    },

    focus: function() {
      this.element.focus();
    },

    applyValue: function(item, state) {
      item[this.column.field] = state;
    },

    serializeValue: function() {
      return this.element.val();
    },

    loadValue: function(item) {
      this.defaultValue = item[this.column.field];
      this.element.val(this.defaultValue);
      this.element.select();
    },

    isValueChanged: function() {
      return (this.element.val() != this.defaultValue);
    },

    validate: function() {
      return {
        valid: true,
        msg: null
      };
    },

    validateNumber: function() {
      if (isNaN(this.element.val())) {
        this.element.val(this.defaultValue);
        return {
          valid: false,
          msg: "Please enter a valid number."
        };
      } else {
        return {
          valid: true,
          msg: null
        };
      }
    },

    getWrapper: function() {
      return this.wrapper;
    },

    setWrapper: function(wrapper) {
      this.wrapper = wrapper;
    },

    getElement: function() {
      return this.element;
    },

    setElement: function(element) {
      this.element = element;
    },

    getValue: function() {
      return this.element.val();
    },

    setValue: function(val) {
      this.element.val(val);
    },

    getCell: function() {
      return this.element.parent();
    },

    callValidator: function(value) {
      if ($.isFunction(this.column.validator)) {
        return this.column.validator(args, value);
      } else {
        return eval(this.column.validator)(args, value);
      }
    },

    setOffset: function(element, offsetWith) {
      var winWith = $(window).width(),
          offsetLeft = this.element.offset().left;
      if (winWith - offsetLeft < offsetWith) {
        this.element.offset({
          left: winWith - offsetWith
        });
      }
    }
  }

  ///////////////////////////////////////////////////////////////////////////
  // InputElementEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  function InputElementEditor(args) {
    BaseEditor.call(this, args);

    this.boxWidth = this.column.width;
    this.offsetWith = this.boxWidth + 28;

    this.initElements = function() {
      this.input = $("<INPUT type=text class='editor-text' style='width:" + this.boxWidth + "px;border:none;' />");
      this.setElement(this.input);

      this.input.on("keydown.nav", function(e) {
        if (e.keyCode === $.ui.keyCode.LEFT || e.keyCode === $.ui.keyCode.RIGHT) {
          e.stopImmediatePropagation();
        }
      });

      this.input.appendTo(this.args.container);
      this.input.focus().select();
    };

    this.initAwesomplete = function($input) {
      this.awesomplete = new Awesomplete($input[0], {
        minChars: 1,
        maxItems: 5,
        autoFirst: true
      });

      $input.on("keydown", function(e) {
        if ((e.keyCode === $.ui.keyCode.UP) || ((e.keyCode === $.ui.keyCode.DOWN))) {
          e.stopPropagation();
        }
      });

      $.getJSON(args.column.choices, function(data) {
        this.awesomplete.list = data;
      }.bind(this));
    };

    this.isValueChanged = function() {
      return (!(this.input.val() === "" && this.defaultValue === null)) && (this.input.val() != this.defaultValue);
    };
  }

  InputElementEditor.prototype = Object.create(BaseEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // IntegerEditor < InputElementEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  this.IntegerEditor = function(args) {
    InputElementEditor.call(this, args);

    this.init = function() {
      this.initElements();
      this.setOffset(this.input, this.offsetWith);
    };

    this.serializeValue = function() {
      return parseInt(this.input.val(), 10) || 0;
    };

    this.validate = function() {
      return this.validateNumber();
    };

    this.init();
  };

  IntegerEditor.prototype = Object.create(InputElementEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // DecimalEditor < InputElementEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  this.DecimalEditor = function(args) {
    InputElementEditor.call(this, args);

    this.init = function() {
      this.initElements();
      this.setOffset(this.input, this.offsetWith);
    };

    this.serializeValue = function() {
      return this.input.val() || '';
    };

    this.validate = function() {
      return this.validateNumber();
    };

    this.init();
  };

  DecimalEditor.prototype = Object.create(InputElementEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // YesNoCheckboxEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  this.YesNoCheckboxEditor = function(args) {
    BaseEditor.call(this, args);

    this.init = function() {
      this.checkbox = $("<INPUT type=checkbox class='editor-checkbox' hideFocus>");
      this.setElement(this.checkbox);
      this.checkbox.appendTo(this.args.container);
      this.checkbox.focus().select();
    };

    this.loadValue = function(item) {
      this.defaultValue = item[this.column.field];
      if (this.defaultValue) {
        this.checkbox.attr("checked", "checked");
      } else {
        this.checkbox.removeAttr("checked");
      }
    };

    this.serializeValue = function() {
      return this.checkbox[0].checked;
    };

    this.isValueChanged = function() {
      return (this.checkbox[0].checked != this.defaultValue);
    };

    this.init();
  }

  YesNoCheckboxEditor.prototype = Object.create(BaseEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // SelectElementEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  function SelectElementEditor(args) {
    BaseEditor.call(this, args);

    this.choices = this.column.choices;

    // find originColumn
    for (var k in args.grid.originColumns) {
      if (args.grid.originColumns[k].name == this.column.name) {
        this.originColumn = args.grid.originColumns[k];
        break;
      }
    }

    this.boxWidth = (this.column.width < this.originColumn.width) ? this.originColumn.width : this.column.width;
    this.offsetWith = this.boxWidth + 28;

    this.initElements = function() {
      this.wrapper = $("<DIV style='z-index:10000;position:absolute;background:white;padding:3px;margin:-3px 0 0 -7px;border:3px solid gray; -moz-border-radius:10px; border-radius:10px;'/>");
      this.setWrapper(this.wrapper);
      this.wrapper.appendTo(this.args.container);

      this.select = $("<select class='chzn-select' style='width:" + this.boxWidth + "px'></select>");
      this.setElement(this.select);
      this.select.appendTo(this.wrapper);
      this.select.focus();

      this.setOffset(this.wrapper, this.offsetWith);

      this.select.append($("<option />"));
    };

    this.openDropDrown = function() {
      setTimeout(function() {
        this.select.trigger('liszt:open');
      }.bind(this), 300);
    };

    this.setAllowSingleDeselect = function() {
      this.select.chosen({
        allow_single_deselect: !args.column['required']
      });
    };
  }

  SelectElementEditor.prototype = Object.create(BaseEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // SelectEditor < SelectElementEditor < BaseEditor
  // 1. Provide options from pre-defined arrays for `string` type columns
  // 2. Use jquery.chosen to allow you choose the value as select
  ///////////////////////////////////////////////////////////////////////////

  this.SelectEditor = function(args) {
    SelectElementEditor.call(this, args);

    this.init = function() {
      var choices = this.column.choices;
      var selectOptions;

      this.initElements();

      // get choices options from choices_column value
      if (!this.choices && this.column.choices_column) {
        choices = args.item[this.column.choices_column];
      }

      // construce select option
      if ($.isArray(choices)) {
        selectOptions = $.map(choices, function(e, index) {
          if ($.isPlainObject(e)) {
            return e;
          } else {
            return { id: e, name: e };
          }
        });
      } else if ($.isPlainObject(choices)) {
        selectOptions = {};
        for (var i in choices) {
          if ($.isEmptyObject(choices[i])) {
            selectOptions[i] = [];
          } else {
            var option = $.map(choices[i], function(e, index) {
              return { id: e, name: e };
            });
            selectOptions[i] = option;
          }
        }
      }

      // Filter the choices if it depend on other column's value
      if (this.column.depend_column) {
        selectOptions = selectOptions[args.item[this.column.depend_column]];
      }

      // Append the current value option, otherwise this.serializeValue can't get it
      if (args.item[this.column.field]) {
        this.select.append("<option style='display: none;' value='" + args.item[this.column.field] + "'>" + args.item[this.column.field] + "</option>");
        this.select.val(args.item[this.column.field]);
      }

      // Append options from choices array
      $.each(selectOptions, function(index, value) {
        value = value.name || value;
        this.select.append("<option value='" + value + "'>" + value + "</option>")
      }.bind(this));

      this.setAllowSingleDeselect();
      this.openDropDrown();
    };

    this.init();
  }

  SelectEditor.prototype = Object.create(SelectElementEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // DistinctEditor < SelectElementEditor < BaseEditor
  // 1. Provide distinct options from the string column with repeatable items
  // 2. Use jquery.chosen to allow you choose the value as select
  ///////////////////////////////////////////////////////////////////////////

  this.DistinctEditor = function(args) {
    SelectElementEditor.call(this, args);

    this.source = this.column.source || 'name';
    this.addOptionText = 'Add new Option';
    this.bottomOption = '<option>' + this.addOptionText + '</option>';

    this.init = function() {
      this.initElements();
      this.getOptions();
      this.openDropDrown();
    };

    this.addNewOptionHandler = function() {
      var _self = this;

      $('#' + _self.select.attr('id') + '_chzn li:contains("' + _self.addOptionText + '")').off('mouseup').on('mouseup', function(event) {
        var $dialog = $("<div/>").attr({
          id: 'distinct_dialog',
          title: "Add new " + _self.column.name,
          'class': "create_form"
        }).css('display', 'none').appendTo($('body'));
        var $fieldDiv = $("<div />").attr({
          style: 'padding: 20px 30px;'
        });
        var $submitDiv = $("<div />").attr({
          style: 'padding: 0 30px;'
        });
        $fieldDiv.append('<label for="distinct_field" style="display: inline-block; margin-right: 6px;">' + _self.column.name + '</label>');
        $fieldDiv.append('<input id="distinct_field" type="text" style="width: 250px" size="30" name="distinct_field">');
        $fieldDiv.appendTo($dialog);
        $submitDiv.append('<input id="distinct_submit" class="btn success" type="submit" value=" Add ' + _self.column.name + ' " name="commit">');
        $submitDiv.appendTo($dialog);
        $dialog.dialog({
          autoOpen: true,
          width: 450,
          height: 180,
          modal: true,
          buttons: {
            "Cancel": function() {
              $(this).dialog("destroy");
              $(this).remove();
            }
          },
          open: function(event, ui) {
            $('#distinct_submit', $(this)).on('click', function() {
              var optionText = $('#distinct_dialog #distinct_field').val();
              if (optionText) {
                $('option:contains("' + _self.addOptionText + '")', _self.select).before('<option value="' + optionText + '">' + optionText + '</option>');
                _self.select.val(optionText);
                _self.select.trigger('liszt:updated');
                $dialog.dialog("destroy");
                $dialog.remove();
              } else {
                alert('New ' + _self.column.name + ' can not be blank!');
              }
            });
          },
          close: function(event, ui) {
            $(this).dialog("destroy");
            $(this).remove();
          }
        });

        return false;
      });
    };

    this.getOptions = function() {
      $.getJSON(this.choices, function(itemdata) {

        // set options with AJAX
        var ajaxOptions = [];
        $.each(itemdata, function(index, value) {
          ajaxOptions.push("<option value='" + value + "'>" + value + "</option>");
        });
        this.select.append(ajaxOptions.join(''));

        // append 'Add new options' option
        this.select.append(this.bottomOption);

        this.select.val(args.item[this.column.field]);
        this.setAllowSingleDeselect();

        // 'Add new option' option handler
        this.addNewOptionHandler();
      }.bind(this));
    };

    this.init();
  }

  DistinctEditor.prototype = Object.create(SelectElementEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // RelationEditor < SelectElementEditor < BaseEditor
  // - Use jquery.chosen to choose options from a relation column
  ///////////////////////////////////////////////////////////////////////////

  function RelationEditor(args) {
    SelectElementEditor.call(this, args);

    this.source = this.column.source || 'name';
    this.addOptionText = 'Add new Option';
    this.relationColumn = (this.column.type === 'has_and_belongs_to_many') || (this.column.type === 'has_many');

    this.isValueChanged = function() {
      // return true if the value(s) being edited by the user has/have been changed
      var selectedValue = this.select.val();
      if (this.relationColumn) {
        if (selectedValue) {
          if (selectedValue.length != this.defaultValue.length) {
            return true;
          } else {
            return $.difference(this.defaultValue, selectedValue).length !== 0;
          }
        } else {
          return this.defaultValue.length > 0;
        }
      } else {
        return (selectedValue != this.defaultValue);
      }
    };

    this.serializeValue = function() {
      // return the value(s) being edited by the user in a serialized form
      // can be an arbitrary object
      // the only restriction is that it must be a simple object that can be passed around even
      // when the editor itself has been destroyed
      var obj = {};
      obj["id"] = this.select.val();
      obj[this.source] = $('option:selected', this.select).text();

      // special case for has_and_belongs_to_many
      if (this.column.type === 'has_and_belongs_to_many') {
        obj[this.source] = $.map($('option:selected', this.select), function(n) {
          return $(n).text();
        }).join();
      }
      return obj;
    };

    this.loadValue = function(item) {
      // load the value(s) from the data item and update the UI
      // this method will be called immediately after the editor is initialized
      // it may also be called by the grid if if the row/cell being edited is updated via grid.updateRow/updateCell
      this.defaultValue = item[this.column.field].id
      this.select.val(this.defaultValue);
      this.select.select();
    };

    this.getOptions = function(theCurrentValue) {

      // dynamic filter by other relational column
      if (this.args.column.depend_column) {
        var relation_id = this.args.item[this.args.column.depend_column].id;
        this.choices += '&master_model=' + this.args.column.depend_column + '&master_id=' + relation_id;
      }

      $.getJSON(this.choices, function(itemdata) {

        // set options with AJAX
        var ajaxOptions = [];
        $.each(itemdata, function(index, value) {
          if (!this.args.item[this.column.field] || this.args.item[this.column.field].id != value.id)
            ajaxOptions.push("<option value='" + value.id + "'>" + value[this.source] + "</option>");
        }.bind(this));
        this.select.append(ajaxOptions.join(''));

        this.setAllowSingleDeselect();

      }.bind(this));
    };

    this.applyValue = function(item, state) {
      // deserialize the value(s) saved to "state" and apply them to the data item
      // this method may get called after the editor itself has been destroyed
      // treat it as an equivalent of a Java/C# "static" method - no instance variables should be accessed
      item[this.column.field].id = state.id;
      item[this.column.field][this.source] = state[this.source];
    };
  }

  RelationEditor.prototype = Object.create(SelectElementEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // OtherReationEditor < RelationEditor < SelectElementEditor < BaseEditor
  // - Provide options for `belong_to`, `has_one`, `has_and_belongs_to_many` type columns
  ///////////////////////////////////////////////////////////////////////////

  this.OtherRelationEditor = function(args) {
    RelationEditor.call(this, args);

    this.init = function() {
      this.initElements();

      if (this.relationColumn) {
        this.select.attr('multiple', 'true');
      }

      // must append the current value option, otherwise this.serializeValue can't get it
      this.select.append($("<option />"));
      if (this.args.item[this.column.field] && this.args.item[this.column.field].id) {
        this.select.append("<option value='" + this.args.item[this.column.field].id + "'>" + this.args.item[this.column.field][this.source] + "</option>");
        this.select.val(this.args.item[this.column.field].id);
      }

      if ($.isArray(this.choices)) {
        var arrOptions = [];
        $.each(this.choices, function(index, value) {
          if (!args.item[this.column.field] || args.item[this.column.field].id != value.id) {
            arrOptions.push("<option value='" + value.id + "'>" + value[this.source] + "</option>");
          }
        }.bind(this));
        this.select.append(arrOptions.join(''));
        this.select.chosen({
          allow_single_deselect: !args.column['required']
        });
      } else {
        this.getOptions();
      }

      // this.getOptions();
      this.openDropDrown();
    };

    this.init();
  }

  OtherRelationEditor.prototype = Object.create(RelationEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // HasManyEditor < RelationEditor < SelectElementEditor < BaseEditor
  // - Provide options for `has_many` type columns
  ///////////////////////////////////////////////////////////////////////////

  this.HasManyEditor = function(args) {
    RelationEditor.call(this, args);

    this.init = function() {
      this.initElements();

      if (this.relationColumn) {
        this.select.attr('multiple', 'true');
      }

      this.select.empty();
      this.select.append($("<option />"));

      this.getOptions();
      this.openDropDrown();
    };

    this.getOptions = function(theCurrentValue) {
      $.getJSON(this.choices, function(itemdata) {

        // set select options with AJAX
        this.select.empty();
        this.select.append($("<option />"));
        $.each(itemdata, function(index, value) {
          this.select.append("<option value='" + value.id + "'>" + value[this.source] + "</option>");
        }.bind(this));

        this.select.val(args.item[this.column.field].id);
        this.setAllowSingleDeselect();

      }.bind(this));
    };

    this.applyValue = function(item, state) {
      // deserialize the value(s) saved to "state" and apply them to the data item
      // this method may get called after the editor itself has been destroyed
      // treat it as an equivalent of a Java/C# "static" method - no instance variables should be accessed
      if (state.id === null) {
        item[this.column.field] = 'null';
      } else {
        item[this.column.field] = state;
      }
    };

    this.init();
  }

  HasManyEditor.prototype = Object.create(RelationEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // TextEditor < InputElementEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  this.TextEditor = function(args) {
    InputElementEditor.call(this, args);

    this.init = function() {
      this.initElements();
      this.setOffset(this.input, this.offsetWith);
      this.initAwesomplete(this.input);
    };

    this.validate = function() {
      var validationResults;
      var value = this.element.val();

      if (this.column.validator) {
        validationResults = this.callValidator(value);
        if (!validationResults.valid) {
          return validationResults;
        }
      }

      return { valid: true, msg: null };
    };

    this.init();
  }

  TextEditor.prototype = Object.create(InputElementEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // TextEditorForForm < InputElementEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  this.TextEditorForForm = function(args) {
    InputElementEditor.call(this, args);

    this.init = function() {
      this.initAwesomplete(args.container);
    };

    this.init();
  }

  TextEditorForForm.prototype = Object.create(InputElementEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // TextAreaEditor < BaseEditor
  // 1. An example of a "detached" editor.
  // 2. The UI is added onto document BODY and .position(), .show() and .hide() are implemented.
  // 3. KeyDown events are also handled to provide handling for Tab, Shift-Tab, Esc and Ctrl-Enter.
  ///////////////////////////////////////////////////////////////////////////

  this.TextAreaEditor = function(args) {
    BaseEditor.call(this, args);

    var _self = this;

    this.boxWidth = 250;
    this.offsetWith = this.boxWidth + 18;

    this.init = function() {
      this.wrapper = $("<DIV style='z-index:10000;position:absolute;background:white;padding:5px;border:3px solid gray; -moz-border-radius:10px; border-radius:10px;'/>");
      this.setWrapper(this.wrapper);
      this.wrapper.appendTo($("body"));

      this.textArea = $("<TEXTAREA hidefocus rows=5 style='backround:white;width:" + this.boxWidth + "px;height:80px;border:0;outline:0'>");
      this.setElement(this.textArea);
      this.textArea.appendTo(this.wrapper);

      $("<DIV style='text-align:right'><BUTTON>Save</BUTTON><BUTTON>Cancel</BUTTON></DIV>")
        .appendTo(this.wrapper);

      this.wrapper.find("button:first").on("click", this.save);
      this.wrapper.find("button:last").on("click", this.cancel);
      this.textArea.on("keydown", this.handleKeyDown);

      this.position(args.position);
      this.textArea.focus().select();
    };

    this.handleKeyDown = function(e) {
      if (e.which == $.ui.keyCode.ENTER && e.ctrlKey) {
        _self.save();
      } else if (e.which == $.ui.keyCode.ESCAPE) {
        e.preventDefault();
        _self.cancel();
      } else if (e.which == $.ui.keyCode.TAB && e.shiftKey) {
        e.preventDefault();
        args.grid.navigatePrev();
      } else if (e.which == $.ui.keyCode.TAB) {
        e.preventDefault();
        args.grid.navigateNext();
      }
    };

    this.save = function() {
      args.commitChanges();
    };

    this.cancel = function() {
      _self.textArea.val(_self.defaultValue);
      args.cancelChanges();
    };

    this.hide = function() {
      this.wrapper.hide();
    };

    this.show = function() {
      this.wrapper.show();
    };

    this.position = function(position) {
      var winWith = $(window).width(),
          offsetLeft = this.wrapper.offset().left;
      this.wrapper.css({
        "top": position.top - 5,
        "left": position.left - 5
      });
      if (winWith - offsetLeft < this.offsetWith)
        this.wrapper.offset({
          left: winWith - this.offsetWith
        });
    };

    this.isValueChanged = function() {
      return (!(this.textArea.val() === "" && this.defaultValue === null)) && (this.textArea.val() != this.defaultValue);
    };

    this.init();
  }

  TextAreaEditor.prototype = Object.create(BaseEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // DateTimeBaseEditor < InputElementEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  function DateTimeBaseEditor(args) {
    InputElementEditor.call(this, args);

    var date = convertDateTimeFormat(this.args.item[this.column.field]);;
    var dateNow = new Date();
    this.yearNow = dateNow.getFullYear();
    this.boxWidth -= 24;

    this.initInputmaskConfig = {
      yearrange: { minyear: 1900, maxyear: 2100 },
    };

    this.initFlatpickrConfig = {
      allowInput: true,
      clickOpens: false,
      maxDate: '31/12/2100',
      minDate: '01/01/1900',
      onReady: function(selectedDates, dateStr, instance) {
        instance.open();
        instance.update(date);
      },
    };

    this.loadValue = function(item) {
      this.defaultValue = date;
      this.element.val(this.defaultValue);
      this.element.select();
    };
  }

  DateTimeBaseEditor.prototype = Object.create(InputElementEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // DateTimeEditor < InputElementEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  this.DateTimeEditor = function(args) {
    DateTimeBaseEditor.call(this, args);

    this.init = function() {
      var inputmaskConfig = $.extend({}, this.initInputmaskConfig, {
        alias: 'datetime',
        placeholder: 'dd/mm/' + this.yearNow + ' 12:00',
      });

      var flatpickrConfig = $.extend({}, this.initFlatpickrConfig, {
        enableTime: true,
        dateFormat: 'd/m/Y H:i',
      });

      this.initElements();
      Inputmask.extendAliases({ 'gridDateTime': inputmaskConfig });
      this.input.inputmask('gridDateTime').flatpickr(flatpickrConfig);
    };

    this.init();
  }

  DateTimeEditor.prototype = Object.create(DateTimeBaseEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // DateEditor < InputElementEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  this.DateEditor = function(args) {
    DateTimeBaseEditor.call(this, args);

    this.init = function() {
      var inputmaskConfig = $.extend({}, this.initInputmaskConfig, {
        alias: 'date',
        placeholder: 'dd/mm/' + this.yearNow,
      });

      var flatpickrConfig = $.extend({}, this.initFlatpickrConfig, {
        dateFormat: 'd/m/Y',
      });

      this.initElements();
      Inputmask.extendAliases({ 'gridDate': inputmaskConfig });
      this.input.inputmask('gridDate').flatpickr(flatpickrConfig);
    };

    this.init();
  }

  DateEditor.prototype = Object.create(DateTimeBaseEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // TimeEditor < InputElementEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  this.TimeEditor = function(args) {
    InputElementEditor.call(this, args);

    this.init = function() {
      this.setDateTimeFormates();
      this.boxWidth -= 24;
      this.initElements();
    };

    this.loadValue = function(item) {
      BaseEditor.prototype.loadValue.call(this, item);

      $.extend(this.datePickerOptions, {
        timeFormat: this.timeShowFormat,
        stepMinute: 5
      });

      if (item.unit) {
        if (item.unit.unit == "mn")
          $.extend(this.datePickerOptions, {
            minuteGrid: 5
          });
        else if (item.unit.unit == 'slot')
          $.extend(this.datePickerOptions, {
            minuteGrid: 10
          });
      }

      this.input.timepicker(this.datePickerOptions);
    };

    this.validate = function() {
      return this.validateDateTime('parseTime', 'Time');
    };

    this.serializeValue = function() {
      return this.serializeDateTime('parseTime');
    };

    this.init();
  }

  TimeEditor.prototype = Object.create(InputElementEditor.prototype);

  // TODO: Remove
  this.SimpleDateEditor = function(args) {
    var column = args.column;
    var $input;
    var defaultValue;
    var scope = this;
    var boxWidth = column.width;
    var offsetWith = boxWidth + 18;

    this.init = function() {
      $wrapper = $("<DIV style='z-index:10000;position:absolute;background:white;padding:3px;margin:-3px 0 0 -7px;border:3px solid gray; -moz-border-radius:10px; border-radius:10px;'/>")
        .appendTo(args.container);
      $input = $("<INPUT type=text class='editor-text' style='width:" + boxWidth + "px;border:0' />")
        .appendTo($wrapper)
        .bind("keydown.nav", function(e) {
          if (e.keyCode === $.ui.keyCode.LEFT || e.keyCode === $.ui.keyCode.RIGHT) {
            e.stopImmediatePropagation();
          }
        })
        .scrollLeft(0)
        .focus()
        .select();
      var winWith = $(window).width(),
        offsetLeft = $wrapper.offset().left;
      if (winWith - offsetLeft < offsetWith)
        $wrapper.offset({
          left: winWith - offsetWith
        });
    };

    this.destroy = function() {
      $input.remove();
    };

    this.focus = function() {
      $input.focus();
    };

    this.getValue = function() {
      return $input.val();
    };

    this.setValue = function(val) {
      $input.val(val);
    };

    this.loadValue = function(item) {
      defaultValue = item[column.field] || "";
      $input[0].defaultValue = defaultValue;
      $input.select();
    };

    this.serializeValue = function() {
      return $input.val();
    };

    this.applyValue = function(item, state) {
      item[column.field] = state;
    };

    this.isValueChanged = function() {
      return (!($input.val() === "" && defaultValue === null)) && ($input.val() != defaultValue);
    };

    this.validate = function() {
      var validationResults;
      var currentValue = $input.val();
      if (column.validator) {
        if ($.isFunction(column.validator)) {
          validationResults = column.validator(args, currentValue);
        } else {
          validationResults = eval(column.validator)(args, currentValue);
        }
        if (!validationResults.valid)
          return validationResults;
      }

      if (currentValue) {
        if (!ParseSimpleDate(currentValue)) {
          $input.val(defaultValue);
          return {
            valid: false,
            msg: "Please enter a valid Date"
          };
        }
      }

      return {
        valid: true,
        msg: null
      };
    };

    this.getCell = function() {
      return $input.parent();
    };

    this.init();
  }

  ///////////////////////////////////////////////////////////////////////////
  // DateTimeBaseEditor < InputElementEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  // this.DateTimeBaseEditor = function(args) {
  //   InputElementEditor.call(this, args);
  //
  //   var REGEX_DATE = '(\\d{4})\\-?(0?[1-9]|1[012])\\-?(0?[1-9]|[12][0-9]|3[01])';
  //   var REGEX_TIME = '(\\d{2}):?(\\d{2})';
  //
  //   this.calendarOpen = false;
  //   this.dateShowFormat = "yy-mm-dd";
  //   this.dateSourceFormat = "yy-mm-dd";
  //   this.timeShowFormat = "HH:mm";
  //
  //   this.datePickerOptions = {
  //     showOn: "button",
  //     buttonImageOnly: true,
  //     buttonImage: "/assets/calendar.gif",
  //     beforeShow: function() {
  //       this.calendarOpen = true;
  //     },
  //     onClose: function() {
  //       this.calendarOpen = false;
  //       e = $.Event("keydown");
  //       e.which = 13;
  //       $(this).trigger(e);
  //     }
  //   };
  //
  //   this.setDateTimeFormates = function() {
  //     if (this.column.DateSourceFormat !== undefined) {
  //       this.dateSourceFormat = this.column.DateSourceFormat;
  //     }
  //     if (this.column.DateShowFormat !== undefined) {
  //       this.dateShowFormat = this.column.DateShowFormat;
  //     }
  //   };
  //
  //   this.parseTime = function(timeStr) {
  //     return timeStr.match(new RegExp('^' + REGEX_TIME + '$'));
  //   };
  //
  //   this.parseDate = function(dateStr) {
  //     return dateStr.match(new RegExp('^' + REGEX_DATE + '$'));
  //   };
  //
  //   this.parseDateTime = function(dateTimeStr) {
  //     return dateTimeStr.match(new RegExp('^' + REGEX_DATE + '[ \\t]?' + REGEX_TIME + '$'));
  //   };
  //
  //   this.validateDateTime = function(parser, msg) {
  //     var validationResults;
  //     var value = this.element.val();
  //
  //     if (this.column.validator) {
  //       validationResults = this.callValidator(value);
  //       if (!validationResults.valid) {
  //         return validationResults;
  //       }
  //     }
  //
  //     if (value) {
  //       if (!eval('this.' + parser)(value)) {
  //         this.element.val(this.defaultValue);
  //         return {
  //           valid: false,
  //           msg: "Please enter a valid " + msg
  //         };
  //       }
  //     }
  //
  //     return {
  //       valid: true,
  //       msg: null
  //     };
  //   };
  //
  //   this.serializeDateTime = function(parser) {
  //     var value = this.element.val();
  //     var matchedArr = eval('this.' + parser)(value);
  //
  //     if (matchedArr) {
  //       switch(parser) {
  //         case 'parseDate':
  //           return matchedArr[1] + '-' + matchedArr[2] + '-' + matchedArr[3];
  //           break;
  //         case 'parseTime':
  //           return matchedArr[1] + ':' + matchedArr[2];
  //           break;
  //         default:
  //           return matchedArr[1] + '-' + matchedArr[2] + '-' + matchedArr[3] + ' ' + matchedArr[4] + ':' + matchedArr[5];
  //       }
  //     } else {
  //       return value;
  //     }
  //   }
  //
  //   this.destroy = function() {
  //     $.datepicker.dpDiv.stop(true, true);
  //     this.input.datetimepicker("hide");
  //     this.input.datepicker("destroy");
  //     this.input.remove();
  //   };
  //
  //   this.show = function() {
  //     if (this.calendarOpen) {
  //       $.datepicker.dpDiv.stop(true, true).show();
  //     }
  //   };
  //
  //   this.hide = function() {
  //     if (this.calendarOpen) {
  //       $.datepicker.dpDiv.stop(true, true).hide();
  //     }
  //   };
  // }

  // DateTimeBaseEditor.prototype = Object.create(InputElementEditor.prototype);

})(jQuery);
