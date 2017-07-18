(function($) {

  // Get current year

  var dateNow = new Date();
  this.yearNow = dateNow.getFullYear();

  // Config of Inputmask

  Inputmask.extendAliases({
    'wulinDateTime': {
      alias: 'datetime',
      placeholder: 'dd/mm/' + this.yearNow + ' 12:00',
      yearrange: { minyear: 1900, maxyear: 2100 },
    }
  });

  Inputmask.extendAliases({
    'wulinDate': {
      alias: 'date',
      placeholder: 'dd/mm/' + this.yearNow,
      yearrange: { minyear: 1900, maxyear: 2100 },
    }
  });

  Inputmask.extendAliases({
    'wulinTime': {
      alias: 'hh:mm',
      placeholder: '12:00',
    }
  });

  // Config of flatpickr

  this.fpConfigInit = {
    allowInput: true,
    maxDate: '31/12/2100',
    minDate: '01/01/1900',
  };

  this.fpConfigForm = $.extend({}, this.fpConfigInit, {
    clickOpens: true,
    onOpen: function(selectedDates, dateStr, instance) {
      instance.update(dateStr);
    },
  });

  this.fpConfigFormDateTime = $.extend({}, this.fpConfigForm, {
    enableTime: true,
    dateFormat: 'd/m/Y H:i',
  });

  this.fpConfigFormDate = $.extend({}, this.fpConfigForm, {
    dateFormat: 'd/m/Y',
  });

  this.fpConfigTime = $.extend({}, this.fpConfigForm, {
    noCalendar: true,
    enableTime: true,
    dateFormat: 'H:i',
    onOpen: function(selectedDates, dateStr, instance) {
      var time = dateStr || '12:00';
      instance.update(time);
    },
  });

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

    this.initMdAutoComplete = function($input) {
      $input.on("keydown", function(e) {
        if ((e.keyCode === $.ui.keyCode.UP) || ((e.keyCode === $.ui.keyCode.DOWN))) {
          e.stopPropagation();
        }
      });

      $.getJSON(args.column.choices, function(dataArray) {
        var dataObject = {};
        for (var i = 0; i < dataArray.length; ++i) {
          dataObject[dataArray[i]] = null;
        }

        $input.addClass('autocomplete');
        $input.autocomplete({
          data: dataObject,
          limit: 5,
          minLength: 1,
        });
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
      var id = 'checkbox-' + this.args.item.id;
      this.checkbox = $('<input type="checkbox">')
        .addClass('filled-in')
        .attr('id', id)
        .appendTo(this.args.container);
      $('<label />').attr('for', id).appendTo(this.args.container);
      this.setElement(this.checkbox);
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
    if (!!this.column.editor.source) {
      var match = /^.*(source=.*)$/igm.exec(this.column.choices);
      var grid_source = match[1];
      this.choices = this.column.choices.replace(grid_source, 'source=' + this.column.editor.source);
    }

    this.field = this.args.item[this.column.field];

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
      this.wrapper = $("<div />");
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

    this.source = this.column.editor.source || this.column.source || 'name';
    this.addOptionText = 'Add new Option';
    this.arrOptions = [];
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

    this.applyValue = function(item, state) {
      // deserialize the value(s) saved to "state" and apply them to the data item
      // this method may get called after the editor itself has been destroyed
      // treat it as an equivalent of a Java/C# "static" method - no instance variables should be accessed
      item[this.column.field].id = state.id;
      item[this.column.field][this.source] = state[this.source];
    };

    this.getOptions = function() {
      // dynamic filter by other relational column
      if (this.args.column.depend_column) {
        var relation_id = this.args.item[this.args.column.depend_column].id;
        this.choices += '&master_model=' + this.args.column.depend_column + '&master_id=' + relation_id;
      }

      $.getJSON(this.choices, function(itemdata) {
        this.setOptions(itemdata);
      }.bind(this));
    };

    this.setOptions = function(dateset) {
      $.each(dateset, function(index, value) {
        if (!this.field || this.field.id != value.id) {
          this.arrOptions.push(
            "<option value='" + value.id + "'>" +
            value[this.source] +
            "</option>"
          );
        }
      }.bind(this));
      this.select.append(this.arrOptions.join(''));
      this.setAllowSingleDeselect();
    };

    this.appendOptions = function(target, value) {
      target.append(
        "<option value='" + value.id + "'>" +
        value[this.source] +
        "</option>"
      );
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
      if (this.field && this.field.id) {
        this.appendOptions(this.select, this.field);
        this.select.val(this.field.id);
      }

      if ($.isArray(this.choices)) {
        this.setOptions(this.choices);
      } else {
        this.getOptions();
      }

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

      $.getJSON(this.choices, function(itemdata) {
        $.each(itemdata, function(index, value) {
          this.appendOptions(this.select, value);
        }.bind(this));
        this.select.val(this.field.id);
        this.setAllowSingleDeselect();
      }.bind(this));

      this.openDropDrown();
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
      // this.initAwesomplete(this.input);
      this.initMdAutoComplete(this.input);
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
      $(args.container).attr('autocomplete', 'off');
      this.initMdAutoComplete(args.container);
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
      this.wrapper = $('<div />').addClass('textarea-wrapper');
      this.setWrapper(this.wrapper);
      this.wrapper.appendTo($("body"));

      this.textArea = $("<textarea hidefocus rows=5>").addClass('textarea-in-grid');
      this.textArea.css('width', this.boxWidth);
      this.setElement(this.textArea);
      this.textArea.appendTo(this.wrapper);

      var $btnSave = $('<button />').text('Save').addClass('btn btn-small right');
      var $btnCancel = $('<button />').text('Cancel').addClass('btn btn-small right');
      $('<div />').append($btnCancel).append($btnSave).appendTo(this.wrapper);

      $btnSave.on("click", this.save);
      $btnCancel.on("click", this.cancel);
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

    var date = this.args.item[this.column.field];
    this.boxWidth -= 24;

    this.fpConfigGrid = $.extend({}, window.fpConfigInit, {
      clickOpens: false,
      onReady: function(selectedDates, dateStr, instance) {
        instance.open();
        instance.update(date);
      },
    });
  }

  DateTimeBaseEditor.prototype = Object.create(InputElementEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // DateTimeEditor < DateTimeBaseEditor < InputElementEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  this.DateTimeEditor = function(args) {
    DateTimeBaseEditor.call(this, args);

    this.init = function() {
      var flatpickrConfig = $.extend({}, this.fpConfigGrid, {
        enableTime: true,
        dateFormat: 'd/m/Y H:i',
      });

      this.initElements();
      this.input.inputmask('wulinDateTime').flatpickr(flatpickrConfig);
    };

    this.init();
  }

  DateTimeEditor.prototype = Object.create(DateTimeBaseEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // DateEditor < DateTimeBaseEditor < InputElementEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  this.DateEditor = function(args) {
    DateTimeBaseEditor.call(this, args);

    this.init = function() {
      var fpConfigGridDate = $.extend({}, this.fpConfigGrid, {
        dateFormat: 'd/m/Y',
      });

      this.initElements();
      this.input.inputmask('wulinDate').flatpickr(fpConfigGridDate);
    };

    this.init();
  }

  DateEditor.prototype = Object.create(DateTimeBaseEditor.prototype);

  ///////////////////////////////////////////////////////////////////////////
  // TimeEditor < DateTimeBaseEditor < InputElementEditor < BaseEditor
  ///////////////////////////////////////////////////////////////////////////

  this.TimeEditor = function(args) {
    DateTimeBaseEditor.call(this, args);

    this.init = function() {
      var fpConfigGridTime = $.extend({}, this.fpConfigGrid, {
        noCalendar: true,
        enableTime: true,
        dateFormat: 'H:i',
      });

      this.initElements();
      this.input.inputmask('wulinTime').flatpickr(fpConfigGridTime);
    };

    this.init();
  }

  TimeEditor.prototype = Object.create(DateTimeBaseEditor.prototype);

})(jQuery);
