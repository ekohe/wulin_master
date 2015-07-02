/***
 * Contains basic SlickGrid editors.
 * @module Editors
 * @namespace Slick
 */

(function ($) {
  // register namespace
  $.extend(true, window, {
    "Slick": {
      "Editors": {
        "Text": TextEditor,
        "Integer": IntegerEditor,
        "Date": DateEditor,
        "YesNoSelect": YesNoSelectEditor,
        "Checkbox": CheckboxEditor,
        "PercentComplete": PercentCompleteEditor,
        "LongText": LongTextEditor,
        "SimpleDate": SimpleDateEditor,
        "Float": FloatEditor,
        "DateTime": DateTimeEditor,
        "Time": TimeEditor,
        "StandardDate": StandardDateEditor,
        "YesNoCheckbox": YesNoCheckboxEditor,
        "Star": StarEditor,
        "BelongsTo": BelongsToEditor,
        "HasMany": HasManyEditor,
        "Select": SelectEditor,
        "DoubleSelect": DoubleSelectEditor,
        "Distinct": DistinctEditor,
        "AutoCompleteText": AutoCompleteTextEditor,
        "AutoCompleteTextForForm": AutoCompleteTextForFormEditor
      }
    }
  });

    function TextEditor(args) {
      var $input;
      var defaultValue;
      var scope = this;

      this.init = function () {
        $input = $("<INPUT type=text class='editor-text' />")
            .appendTo(args.container)
            .bind("keydown.nav", function (e) {
              if (e.keyCode === $.ui.keyCode.LEFT || e.keyCode === $.ui.keyCode.RIGHT) {
                e.stopImmediatePropagation();
              }
            })
            .focus()
            .select();
      };

      this.destroy = function () {
        $input.remove();
      };

      this.focus = function () {
        $input.focus();
      };

      this.getValue = function () {
        return $input.val();
      };

      this.setValue = function (val) {
        $input.val(val);
      };

      this.loadValue = function (item) {
        defaultValue = item[args.column.field] || "";
        $input.val(defaultValue);
        $input[0].defaultValue = defaultValue;
        $input.select();
      };

      this.serializeValue = function () {
        return $input.val();
      };

      this.applyValue = function (item, state) {
        item[args.column.field] = state;
      };

      this.isValueChanged = function () {
        return (!($input.val() == "" && defaultValue == null)) && ($input.val() != defaultValue);
      };

      this.validate = function () {
        if (args.column.validator) {
          var validationResults = args.column.validator($input.val());
          if (!validationResults.valid) {
            return validationResults;
          }
        }

        return {
          valid: true,
          msg: null
        };
      };

      this.init();
    }

    function IntegerEditor(args) {
      var $input;
      var defaultValue;
      var scope = this;

      this.init = function () {
        $input = $("<INPUT type=text class='editor-text' />");

        $input.bind("keydown.nav", function (e) {
          if (e.keyCode === $.ui.keyCode.LEFT || e.keyCode === $.ui.keyCode.RIGHT) {
            e.stopImmediatePropagation();
          }
        });

        $input.appendTo(args.container);
        $input.focus().select();
      };

      this.destroy = function () {
        $input.remove();
      };

      this.focus = function () {
        $input.focus();
      };

      this.loadValue = function (item) {
        defaultValue = item[args.column.field];
        $input.val(defaultValue);
        $input[0].defaultValue = defaultValue;
        $input.select();
      };

      this.serializeValue = function () {
        return parseInt($input.val(), 10) || 0;
      };

      this.applyValue = function (item, state) {
        item[args.column.field] = state;
      };

      this.isValueChanged = function () {
        return (!($input.val() == "" && defaultValue == null)) && ($input.val() != defaultValue);
      };

      this.validate = function () {
        if (isNaN($input.val())) {
          return {
            valid: false,
            msg: "Please enter a valid integer"
          };
        }

        return {
          valid: true,
          msg: null
        };
      };

      this.init();
    }

    function DateEditor(args) {
      var $input;
      var defaultValue;
      var scope = this;
      var calendarOpen = false;

      this.init = function () {
        $input = $("<INPUT type=text class='editor-text' />");
        $input.appendTo(args.container);
        $input.focus().select();
        $input.datepicker({
          showOn: "button",
          buttonImageOnly: true,
          buttonImage: "../images/calendar.gif",
          beforeShow: function () {
            calendarOpen = true
          },
          onClose: function () {
            calendarOpen = false
          }
        });
        $input.width($input.width() - 18);
      };

      this.destroy = function () {
        $.datepicker.dpDiv.stop(true, true);
        $input.datepicker("hide");
        $input.datepicker("destroy");
        $input.remove();
      };

      this.show = function () {
        if (calendarOpen) {
          $.datepicker.dpDiv.stop(true, true).show();
        }
      };

      this.hide = function () {
        if (calendarOpen) {
          $.datepicker.dpDiv.stop(true, true).hide();
        }
      };

      this.position = function (position) {
        if (!calendarOpen) {
          return;
        }
        $.datepicker.dpDiv
            .css("top", position.top + 30)
            .css("left", position.left);
      };

      this.focus = function () {
        $input.focus();
      };

      this.loadValue = function (item) {
        defaultValue = item[args.column.field];
        $input.val(defaultValue);
        $input[0].defaultValue = defaultValue;
        $input.select();
      };

      this.serializeValue = function () {
        return $input.val();
      };

      this.applyValue = function (item, state) {
        item[args.column.field] = state;
      };

      this.isValueChanged = function () {
        return (!($input.val() == "" && defaultValue == null)) && ($input.val() != defaultValue);
      };

      this.validate = function () {
        return {
          valid: true,
          msg: null
        };
      };

      this.init();
    }

    function YesNoSelectEditor(args) {
      var $select;
      var defaultValue;
      var scope = this;

      this.init = function () {
        $select = $("<SELECT tabIndex='0' class='editor-yesno'><OPTION value='yes'>Yes</OPTION><OPTION value='no'>No</OPTION></SELECT>");
        $select.appendTo(args.container);
        $select.focus();
      };

      this.destroy = function () {
        $select.remove();
      };

      this.focus = function () {
        $select.focus();
      };

      this.loadValue = function (item) {
        $select.val((defaultValue = item[args.column.field]) ? "yes" : "no");
        $select.select();
      };

      this.serializeValue = function () {
        return ($select.val() == "yes");
      };

      this.applyValue = function (item, state) {
        item[args.column.field] = state;
      };

      this.isValueChanged = function () {
        return ($select.val() != defaultValue);
      };

      this.validate = function () {
        return {
          valid: true,
          msg: null
        };
      };

      this.init();
    }

    function CheckboxEditor(args) {
      var $select;
      var defaultValue;
      var scope = this;

      this.init = function () {
        $select = $("<INPUT type=checkbox value='true' class='editor-checkbox' hideFocus>");
        $select.appendTo(args.container);
        $select.focus();
      };

      this.destroy = function () {
        $select.remove();
      };

      this.focus = function () {
        $select.focus();
      };

      this.loadValue = function (item) {
        defaultValue = !!item[args.column.field];
        if (defaultValue) {
          $select.prop('checked', true);
        } else {
          $select.prop('checked', false);
        }
      };

      this.serializeValue = function () {
        return $select.prop('checked');
      };

      this.applyValue = function (item, state) {
        item[args.column.field] = state;
      };

      this.isValueChanged = function () {
        return (this.serializeValue() !== defaultValue);
      };

      this.validate = function () {
        return {
          valid: true,
          msg: null
        };
      };

      this.init();
    }

    function PercentCompleteEditor(args) {
      var $input, $picker;
      var defaultValue;
      var scope = this;

      this.init = function () {
        $input = $("<INPUT type=text class='editor-percentcomplete' />");
        $input.width($(args.container).innerWidth() - 25);
        $input.appendTo(args.container);

        $picker = $("<div class='editor-percentcomplete-picker' />").appendTo(args.container);
        $picker.append("<div class='editor-percentcomplete-helper'><div class='editor-percentcomplete-wrapper'><div class='editor-percentcomplete-slider' /><div class='editor-percentcomplete-buttons' /></div></div>");

        $picker.find(".editor-percentcomplete-buttons").append("<button val=0>Not started</button><br/><button val=50>In Progress</button><br/><button val=100>Complete</button>");

        $input.focus().select();

        $picker.find(".editor-percentcomplete-slider").slider({
          orientation: "vertical",
          range: "min",
          value: defaultValue,
          slide: function (event, ui) {
            $input.val(ui.value)
          }
        });

        $picker.find(".editor-percentcomplete-buttons button").bind("click", function (e) {
          $input.val($(this).attr("val"));
          $picker.find(".editor-percentcomplete-slider").slider("value", $(this).attr("val"));
        })
      };

      this.destroy = function () {
        $input.remove();
        $picker.remove();
      };

      this.focus = function () {
        $input.focus();
      };

      this.loadValue = function (item) {
        $input.val(defaultValue = item[args.column.field]);
        $input.select();
      };

      this.serializeValue = function () {
        return parseInt($input.val(), 10) || 0;
      };

      this.applyValue = function (item, state) {
        item[args.column.field] = state;
      };

      this.isValueChanged = function () {
        return (!($input.val() == "" && defaultValue == null)) && ((parseInt($input.val(), 10) || 0) != defaultValue);
      };

      this.validate = function () {
        if (isNaN(parseInt($input.val(), 10))) {
          return {
            valid: false,
            msg: "Please enter a valid positive number"
          };
        }

        return {
          valid: true,
          msg: null
        };
      };

      this.init();
    }

    /*
     * An example of a "detached" editor.
     * The UI is added onto document BODY and .position(), .show() and .hide() are implemented.
     * KeyDown events are also handled to provide handling for Tab, Shift-Tab, Esc and Ctrl-Enter.
     */
    function LongTextEditor(args) {
      var $input, $wrapper;
      var defaultValue;
      var scope = this;

      this.init = function () {
        var $container = $("body");

        $wrapper = $("<DIV style='z-index:10000;position:absolute;background:white;padding:5px;border:3px solid gray; -moz-border-radius:10px; border-radius:10px;'/>")
            .appendTo($container);

        $input = $("<TEXTAREA hidefocus rows=5 style='backround:white;width:250px;height:80px;border:0;outline:0'>")
            .appendTo($wrapper);

        $("<DIV style='text-align:right'><BUTTON>Save</BUTTON><BUTTON>Cancel</BUTTON></DIV>")
            .appendTo($wrapper);

        $wrapper.find("button:first").bind("click", this.save);
        $wrapper.find("button:last").bind("click", this.cancel);
        $input.bind("keydown", this.handleKeyDown);

        scope.position(args.position);
        $input.focus().select();
      };

      this.handleKeyDown = function (e) {
        if (e.which == $.ui.keyCode.ENTER && e.ctrlKey) {
          scope.save();
        } else if (e.which == $.ui.keyCode.ESCAPE) {
          e.preventDefault();
          scope.cancel();
        } else if (e.which == $.ui.keyCode.TAB && e.shiftKey) {
          e.preventDefault();
          args.grid.navigatePrev();
        } else if (e.which == $.ui.keyCode.TAB) {
          e.preventDefault();
          args.grid.navigateNext();
        }
      };

      this.save = function () {
        args.commitChanges();
      };

      this.cancel = function () {
        $input.val(defaultValue);
        args.cancelChanges();
      };

      this.hide = function () {
        $wrapper.hide();
      };

      this.show = function () {
        $wrapper.show();
      };

      this.position = function (position) {
        $wrapper
            .css("top", position.top - 5)
            .css("left", position.left - 5)
      };

      this.destroy = function () {
        $wrapper.remove();
      };

      this.focus = function () {
        $input.focus();
      };

      this.loadValue = function (item) {
        $input.val(defaultValue = item[args.column.field]);
        $input.select();
      };

      this.serializeValue = function () {
        return $input.val();
      };

      this.applyValue = function (item, state) {
        item[args.column.field] = state;
      };

      this.isValueChanged = function () {
        return (!($input.val() == "" && defaultValue == null)) && ($input.val() != defaultValue);
      };

      this.validate = function () {
        return {
          valid: true,
          msg: null
        };
      };

      this.init();
    }

    function SimpleDateEditor(args) {
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

    function FloatEditor(args) {
      var column = args.column;
      var $input;
      var defaultValue;
      var scope = this;
      var boxWidth = column.width;
      var offsetWith = boxWidth + 28;

      this.init = function() {
        $input = $("<INPUT type=text class='editor-text' style='width:" + boxWidth + "px;border:none;' />");

        $input.bind("keydown.nav", function(e) {
          if (e.keyCode === $.ui.keyCode.LEFT || e.keyCode === $.ui.keyCode.RIGHT) {
            e.stopImmediatePropagation();
          }
        });

        $input.appendTo(args.container);
        $input.focus().select();
        var winWith = $(window).width(),
          offsetLeft = $input.offset().left;
        if (winWith - offsetLeft < offsetWith)
          $input.offset({
            left: winWith - offsetWith
          });
      };

      this.destroy = function() {
        $input.remove();
      };

      this.focus = function() {
        $input.focus();
      };

      this.loadValue = function(item) {
        defaultValue = item[column.field];
        $input.val(defaultValue);
        $input[0].defaultValue = defaultValue;
        $input.select();
      };

      this.serializeValue = function() {
        return $input.val() || "";
      };

      this.applyValue = function(item, state) {
        item[column.field] = state;
      };

      this.isValueChanged = function() {
        return (!($input.val() === "" && defaultValue === null)) && ($input.val() != defaultValue);
      };

      this.validate = function() {
        if (isNaN($input.val())) {
          $input.val(defaultValue);
          return {
            valid: false,
            msg: "Please enter a valid integer"
          };
        } else {
          return {
            valid: true,
            msg: null
          };
        }
      };

      this.getCell = function() {
        return $input.parent();
      };

      this.init();
    }

    function DateTimeEditor(args) {
      var column = args.column;
      var $input;
      var defaultValue;
      var scope = this;
      var calendarOpen = false;

      this.init = function() {
        $input = $("<INPUT type=text class='editor-text' />").off('keydown.nav').on("keydown.nav", function(e) {
          if (e.keyCode === $.ui.keyCode.LEFT || e.keyCode === $.ui.keyCode.RIGHT) {
            e.stopImmediatePropagation();
          }
        });
        $input.appendTo(args.container);
        $input.focus().select();
        $input.width($input.width() - 18);
      };

      this.destroy = function() {
        $.datepicker.dpDiv.stop(true, true);
        $input.datetimepicker("hide");
        $input.remove();
      };

      this.show = function() {
        if (calendarOpen) {
          $.datepicker.dpDiv.stop(true, true).show();
        }
      };

      this.hide = function() {
        if (calendarOpen) {
          $.datepicker.dpDiv.stop(true, true).hide();
        }
      };

      this.position = function(position) {
        if (!calendarOpen) return;
        $.datepicker.dpDiv
          .css("top", position.top + 30)
          .css("left", position.left);
      };

      this.focus = function() {
        $input.focus();
      };

      this.loadValue = function(item) {
        defaultValue = item[column.field];
        $input.val(defaultValue);
        $input[0].defaultValue = defaultValue;
        $input.select();
        $input.datetimepicker({
          showOn: "button",
          buttonImageOnly: true,
          timeOnly: false,
          stepMinute: 1,
          minuteGrid: 0,
          buttonImage: "/assets/calendar.gif",
          beforeShow: function() {
            calendarOpen = true;
          },
          onClose: function() {
            calendarOpen = false;
            e = $.Event("keydown");
            e.which = 13;
            $(this).trigger(e);
          },
          dateFormat: "yy-mm-dd",
          timeFormat: 'HH:mm'
        });
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

    // Time editor, only
    function TimeEditor(args) {
      var column = args.column;
      var $input;
      var defaultValue;
      var scope = this;
      var calendarOpen = false;

      this.init = function() {
        $input = $("<INPUT type=text class='editor-text' />").off('keydown.nav').on("keydown.nav", function(e) {
          if (e.keyCode === $.ui.keyCode.LEFT || e.keyCode === $.ui.keyCode.RIGHT) {
            e.stopImmediatePropagation();
          }
        });
        $input.appendTo(args.container);
        $input.focus().select();
        $input.width($input.width() - 18);
      };

      this.destroy = function() {
        $.datepicker.dpDiv.stop(true, true);
        $input.datetimepicker("hide");
        $input.remove();
      };

      this.show = function() {
        if (calendarOpen) {
          $.datepicker.dpDiv.stop(true, true).show();
        }
      };

      this.hide = function() {
        if (calendarOpen) {
          $.datepicker.dpDiv.stop(true, true).hide();
        }
      };

      this.position = function(position) {
        if (!calendarOpen) return;
        $.datepicker.dpDiv
          .css("top", position.top + 30)
          .css("left", position.left);
      };

      this.focus = function() {
        $input.focus();
      };

      this.loadValue = function(item) {
        defaultValue = item[column.field];
        $input.val(defaultValue);
        $input[0].defaultValue = defaultValue;
        $input.select();
        var attrs = {
          showOn: "button",
          buttonImageOnly: true,
          buttonImage: "/assets/calendar.gif",
          beforeShow: function() {
            calendarOpen = true;
          },
          onClose: function() {
            calendarOpen = false;
            calendarOpen = false;
            e = $.Event("keydown");
            e.which = 13;
            $(this).trigger(e);
          },
          timeFormat: 'HH:mm'
        };
        if (item.unit) {
          if (item.unit.unit == "mn")
            $.extend(attrs, {
              stepMinute: 5,
              minuteGrid: 5
            });
          else if (item.unit.unit == 'slot')
            $.extend(attrs, {
              stepMinute: 5,
              minuteGrid: 10
            });
        }
        $input.timepicker(attrs);
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
        var currentValue = $input.val();
        if (currentValue) {
          if (!ParseSimpleTime(currentValue)) {
            $input.val(defaultValue);
            return {
              valid: false,
              msg: "Please enter a valid Time"
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

    // Date editor which can handle "yy-mm-dd" format
    function StandardDateEditor(args) {
      var column = args.column;
      var $input;
      var defaultValue;
      var scope = this;
      var calendarOpen = false;
      var showFormat = "yy-mm-dd";
      var sourceFormat = "yy-mm-dd";

      this.init = function() {
        if (column.DateSourceFormat !== undefined) {
          sourceFormat = column.DateSourceFormat;
        }
        if (column.DateShowFormat !== undefined) {
          showFormat = column.DateShowFormat;
        }
        $input = $("<INPUT type=text class='editor-text' />");
        $input.appendTo(args.container);
        $input.focus().select();
        $input.datepicker({
          showOn: "button",
          buttonImageOnly: true,
          buttonImage: "/assets/calendar.gif",
          beforeShow: function() {
            calendarOpen = true;
          },
          onClose: function() {
            calendarOpen = false;
            calendarOpen = false;
            e = $.Event("keydown");
            e.which = 13;
            $(this).trigger(e);
          },
          dateFormat: showFormat
        });
        $input.width($input.width() - 18);
      };

      this.destroy = function() {
        $.datepicker.dpDiv.stop(true, true);
        $input.datepicker("hide");
        $input.datepicker("destroy");
        $input.remove();
      };

      this.show = function() {
        if (calendarOpen) {
          $.datepicker.dpDiv.stop(true, true).show();
        }
      };

      this.hide = function() {
        if (calendarOpen) {
          $.datepicker.dpDiv.stop(true, true).hide();
        }
      };

      this.position = function(position) {
        if (!calendarOpen) return;
        $.datepicker.dpDiv
          .css("top", position.top + 30)
          .css("left", position.left);
      };

      this.focus = function() {
        $input.focus();
      };

      this.loadValue = function(item) {
        if (item[column.field]) {
          defaultValue = item[column.field].split(/\s+/)[0];
          if (/^\d{4}(\-|\/|\.)\d{1,2}\1\d{1,2}$/.test(defaultValue)) {
            var thedate = $.datepicker.parseDate(sourceFormat, defaultValue);
            defaultValue = $.datepicker.formatDate(showFormat, thedate);
          } else {
            defaultValue = null;
          }
        } else {
          defaultValue = null;
        }
        $input.val(defaultValue);
        $input[0].defaultValue = defaultValue;
        $input.select();
      };

      this.serializeValue = function() {
        var thedate = $.datepicker.parseDate(showFormat, $input.val());
        return $.datepicker.formatDate(sourceFormat,
          thedate);
      };

      this.applyValue = function(item, state) {
        item[column.field] = state;
      };

      this.isValueChanged = function() {
        return !($input.val() === "" && defaultValue === null) && ($input.val() != defaultValue);
      };

      this.validate = function() {
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

    function YesNoCheckboxEditor(args) {
      var column = args.column;
      var $select;
      var defaultValue;
      var scope = this;

      this.init = function() {
        $select = $("<INPUT type=checkbox class='editor-checkbox' hideFocus>");
        $select.appendTo(args.container);
        $select.focus();
      };

      this.destroy = function() {
        $select.remove();
      };

      this.focus = function() {
        $select.focus();
      };

      this.loadValue = function(item) {
        defaultValue = item[column.field];
        if (defaultValue) {
          $select.prop('checked', true);
        } else {
          $select.prop('checked', false);
        }
      };

      this.serializeValue = function() {
        return $select[0].checked;
      };

      this.applyValue = function(item, state) {
        item[column.field] = state;
      };

      this.isValueChanged = function() {
        var currentValue = $select[0].checked;
        return (currentValue != defaultValue);
      };

      this.validate = function() {
        return {
          valid: true,
          msg: null
        };
      };

      this.getCell = function() {
        return $select.parent();
      };

      this.init();
    }

    function StarEditor(args) {
      var column = args.column;
      var $input;
      var defaultValue;
      var scope = this;

      function toggle(e) {
        if (e.type == "keydown" && e.which != 32) return;

        if ($input.css("opacity") == "1")
          $input.css("opacity", 0.5);
        else
          $input.css("opacity", 1);

        e.preventDefault();
        e.stopPropagation();
        return false;
      }

      this.init = function() {
        $input = $("<IMG src='../images/bullet_star.png' align=absmiddle tabIndex=0 title='Click or press Space to toggle' />")
          .bind("click keydown", toggle)
          .appendTo(args.container)
          .focus();
      };

      this.destroy = function() {
        $input.unbind("click keydown", toggle);
        $input.remove();
      };

      this.focus = function() {
        $input.focus();
      };

      this.loadValue = function(item) {
        defaultValue = item[column.field];
        $input.css("opacity", defaultValue ? 1 : 0.2);
      };

      this.serializeValue = function() {
        return ($input.css("opacity") == "1");
      };

      this.applyValue = function(item, state) {
        item[column.field] = state;
      };

      this.isValueChanged = function() {
        return defaultValue != ($input.css("opacity") == "1");
      };

      this.validate = function() {
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

    // The editor which use jquery.chosen to allow you inputting multiple values that belongs to a record
    function BelongsToEditor(args) {
      var column = args.column;
      var $select, $wrapper;
      var choicesFetchPath = column.choices;
      var optionTextAttribute = column.optionTextAttribute || 'name';
      var defaultValue;
      var originColumn;
      var addOptionText = 'Add new Option';
      var relationColumn = (column.type === 'has_and_belongs_to_many') || (column.type === 'has_many');
      var self = this;
      var virtualGrid = {
        name: column.singular_name,
        path: '/' + column.table,
        query: "?grid=" + column.klass_name + "Grid&screen=" + column.klass_name + "Screen"
      };
      for (var i in args.grid.originColumns) {
        if (args.grid.originColumns[i].name == column.name) {
          originColumn = args.grid.originColumns[i];
          break;
        }
      }
      var boxWidth = (column.width < originColumn.width) ? originColumn.width : column.width;
      var offsetWith = boxWidth + 28;

      this.init = function() {
        $wrapper = $("<DIV style='z-index:10000;position:absolute;background:white;padding:3px;margin:-3px 0 0 -7px;border:3px solid gray; -moz-border-radius:10px; border-radius:10px;'/>")
          .appendTo(args.container);
        if (relationColumn) {
          $select = $("<select class='chzn-select' multiple style='width:" + boxWidth + "px' wid></select>");
        } else {
          $select = $("<select class='chzn-select' style='width:" + boxWidth + "px'></select>");
        }
        $select.appendTo($wrapper);
        $select.focus();
        var winWith = $(window).width(),
          offsetLeft = $wrapper.offset().left;
        if (winWith - offsetLeft < offsetWith) {
          $wrapper.offset({
            left: winWith - offsetWith
          });
        }

        // must append the current value option, otherwise this.serializeValue can't get it
        $select.append($("<option />"));
        if (args.item[column.field] && args.item[column.field].id) {
          $select.append("<option value='" + args.item[column.field].id + "'>" + args.item[column.field][optionTextAttribute] + "</option>");
          $select.val(args.item[column.field].id);
        }

        if ($.isArray(choicesFetchPath)) {
          var arrOptions = [];
          $.each(choicesFetchPath, function(index, value) {
            if (!args.item[column.field] || args.item[column.field].id != value.id)
              arrOptions.push("<option value='" + value.id + "'>" + value[optionTextAttribute] + "</option>");
          });
          $select.append(arrOptions.join(''));
          $select.chosen({
            search_contains: true,
            allow_single_deselect: !args.column['required']
          });
        } else {
          self.getOptions();
        }

        // Open drop-down
        setTimeout(function() {
          $select.trigger('liszt:open');
        }, 300);
      };

      this.getOptions = function(selectedId, theCurrentValue) {
        var self = this;

        // dynamic filter by other relational column
        if (args.column.depend_column) {
          var relation_id = args.item[args.column.depend_column].id;
          choicesFetchPath += '&master_model=' + args.column.depend_column + '&master_id=' + relation_id;
        }
        $.getJSON(choicesFetchPath, function(itemdata) {
          var ajaxOptions = [];
          $.each(itemdata, function(index, value) {
            if (!args.item[column.field] || args.item[column.field].id != value.id)
              ajaxOptions.push("<option value='" + value.id + "'>" + value[optionTextAttribute] + "</option>");
          });
          $select.append(ajaxOptions.join(''));

          if (column.dynamic_options) {
            $select.append('<option>' + addOptionText + '</option>');
          }

          $select.chosen({
            search_contains: true,
            allow_single_deselect: !args.column['required']
          });

          // Update theCurrentValue
          $select.chosen().change(function() {
            theCurrentValue = $select.val();
          });
          theCurrentValue = $select.val();

          // 'Add new option' option handler
          $('#' + $select.attr('id') + '_chzn li:contains("' + addOptionText + '")').off('mouseup').on('mouseup', function(event) {
            event.preventDefault();
            Ui.openModal(virtualGrid, 'wulin_master_option_new_form', null, function() {
              // register 'Create' button click event, need to remove to modal action later
              $('#' + virtualGrid.name + '_option_submit').off('click').on('click', function(e) {
                e.preventDefault();
                Requests.createByAjax({
                  path: virtualGrid.path,
                  name: virtualGrid.name
                }, false, function(data) {
                  self.getOptions(data.id, theCurrentValue);
                  setTimeout(function() {
                    Ui.hideModal(virtualGrid.name);
                  }, 100);
                });
              });
            });
            return false;
          });
        });
      };

      this.destroy = function() {
        // remove all data, events & dom elements created in the constructor
        $wrapper.remove();
      };

      this.focus = function() {
        // set the focus on the main input control (if any)
        $select.focus();
      };

      this.isValueChanged = function() {
        // return true if the value(s) being edited by the user has/have been changed
        var selectedValue = $select.val();
        if (relationColumn) {
          if (selectedValue) {
            if (selectedValue.length != defaultValue.length) {
              return true;
            } else {
              return $.difference(defaultValue, selectedValue).length !== 0;
            }
          } else {
            return defaultValue.length > 0;
          }
        } else {
          return (selectedValue != defaultValue);
        }
      };

      this.serializeValue = function() {
        // return the value(s) being edited by the user in a serialized form
        // can be an arbitrary object
        // the only restriction is that it must be a simple object that can be passed around even
        // when the editor itself has been destroyed
        var obj = {};
        obj["id"] = $select.val();
        obj[optionTextAttribute] = $('option:selected', $select).text();

        // special case for has_and_belongs_to_many
        if (column.type === 'has_and_belongs_to_many') {
          obj[optionTextAttribute] = $.map($('option:selected', $select), function(n) {
            return $(n).text();
          }).join();
        }
        return obj;
      };

      this.loadValue = function(item) {
        // load the value(s) from the data item and update the UI
        // this method will be called immediately after the editor is initialized
        // it may also be called by the grid if if the row/cell being edited is updated via grid.updateRow/updateCell
        defaultValue = item[column.field].id
        $select.val(defaultValue);
        $select.select();
      };

      this.applyValue = function(item, state) {
        // deserialize the value(s) saved to "state" and apply them to the data item
        // this method may get called after the editor itself has been destroyed
        // treat it as an equivalent of a Java/C# "static" method - no instance variables should be accessed
        item[column.field].id = state.id;
        item[column.field][optionTextAttribute] = state[optionTextAttribute];
      };

      this.validate = function() {
        // validate user input and return the result along with the validation message, if any
        // if the input is valid, return {valid:true,msg:null}
        return {
          valid: true,
          msg: null
        };
      };

      this.getCell = function() {
        return $select.parent();
      };

      this.init();
    }

    // This editor is a copy of BelongsToEditor but loads up the initial value differently; eventually this should be all cleaned up
    function HasManyEditor(args) {
      var column = args.column;
      var $select, $wrapper;
      var choicesFetchPath = column.choices;
      var optionTextAttribute = column.optionTextAttribute || 'name';
      var defaultValue;
      var originColumn;
      var addOptionText = 'Add new Option';
      var relationColumn = (column.type === 'has_and_belongs_to_many') || (column.type === 'has_many');
      var self = this;
      var virtualGrid = {
        name: column.singular_name,
        path: '/' + column.table,
        query: "?grid=" + column.klass_name + "Grid&screen=" + column.klass_name + "Screen"
      };
      for (var i in args.grid.originColumns) {
        if (args.grid.originColumns[i].name == column.name) {
          originColumn = args.grid.originColumns[i];
          break;
        }
      }

      var boxWidth = (column.width < originColumn.width) ? originColumn.width : column.width;
      var offsetWith = boxWidth + 28;

      this.init = function() {
        $wrapper = $("<DIV style='z-index:10000;position:absolute;background:white;padding:3px;margin:-3px 0 0 -7px;border:3px solid gray; -moz-border-radius:10px; border-radius:10px;'/>")
          .appendTo(args.container);
        if (relationColumn) {
          $select = $("<select class='chzn-select' multiple style='width:" + boxWidth + "px'></select>");
        } else {
          $select = $("<select class='chzn-select' style='width:" + boxWidth + "px'></select>");
        }

        $select.appendTo($wrapper);
        $select.focus();

        var winWith = $(window).width(),
          offsetLeft = $wrapper.offset().left;
        if (winWith - offsetLeft < offsetWith) {
          $wrapper.offset({
            left: winWith - offsetWith
          });
        }

        $select.empty();
        $select.append($("<option />"));
        if ($.isArray(choicesFetchPath)) {
          $.each(choicesFetchPath, function(index, value) {
            $select.append("<option value='" + value.id + "'>" + value[optionTextAttribute] + "</option>");
          });
          $select.val(args.item[column.field].id);
          $select.chosen({
            search_contains: true,
            allow_single_deselect: !args.column['required']
          });
        } else {
          self.getOptions();
        }

        // Open drop-down
        setTimeout(function() {
          $select.trigger('liszt:open');
        }, 300);
      };

      this.getOptions = function(selectedId, theCurrentValue) {
        var self = this;
        $.getJSON(choicesFetchPath, function(itemdata) {
          $select.empty();
          $select.append($("<option />"));
          $.each(itemdata, function(index, value) {
            $select.append("<option value='" + value.id + "'>" + value[optionTextAttribute] + "</option>");
          });

          if (column.dynamic_options) {
            $select.append('<option>' + addOptionText + '</option>');
          }

          if (selectedId) {
            if (theCurrentValue && relationColumn) {
              theCurrentValue.unshift(selectedId);
              $select.val(theCurrentValue);
            } else {
              $select.val([selectedId]);
            }
            $select.trigger('liszt:updated');
          } else {
            $select.val(args.item[column.field].id);
            $select.chosen({
              search_contains: true,
              allow_single_deselect: !args.column['required']
            });
          }

          // Update theCurrentValue
          $select.chosen().change(function() {
            theCurrentValue = $select.val();
          });
          theCurrentValue = $select.val();

          // 'Add new option' option handler
          $('#' + $select.attr('id') + '_chzn li:contains("' + addOptionText + '")').off('mouseup').on('mouseup', function(event) {
            event.preventDefault();
            Ui.openModal(virtualGrid, 'wulin_master_option_new_form', null, function() {
              // register 'Create' button click event, need to remove to modal action later
              $('#' + virtualGrid.name + '_option_submit').off('click').on('click', function(e) {
                e.preventDefault();
                Requests.createByAjax({
                  path: virtualGrid.path,
                  name: virtualGrid.name
                }, false, function(data) {
                  self.getOptions(data.id, theCurrentValue);
                  setTimeout(function() {
                    Ui.hideModal(virtualGrid.name);
                  }, 100);
                });
              });
            });
            return false;
          });
        });
      };

      this.destroy = function() {
        // remove all data, events & dom elements created in the constructor
        $wrapper.remove();
      };

      this.focus = function() {
        // set the focus on the main input control (if any)
        $select.focus();
      };

      this.isValueChanged = function() {
        // return true if the value(s) being edited by the user has/have been changed
        var selectedValue = $select.val();

        if (relationColumn) {
          if (selectedValue) {
            if (selectedValue.length != defaultValue.length) {
              return true;
            } else {
              return $.difference(defaultValue, selectedValue).length !== 0;
            }
          } else {
            return defaultValue.length > 0;
          }
        } else {
          return (selectedValue != defaultValue);
        }
      };

      this.serializeValue = function() {
        // return the value(s) being edited by the user in a serialized form
        // can be an arbitrary object
        // the only restriction is that it must be a simple object that can be passed around even
        // when the editor itself has been destroyed
        var obj = {
          id: $select.val()
        };
        obj[optionTextAttribute] = $.map($('option:selected', $select), function(n) {
          return $(n).text();
        }).join();
        return obj;
      };

      this.loadValue = function(item) {
        // load the value(s) from the data item and update the UI
        // this method will be called immediately after the editor is initialized
        // it may also be called by the grid if if the row/cell being edited is updated via grid.updateRow/updateCell
        defaultValue = item[column.field].id
        $select.val(defaultValue);
        $select.select();
      };

      this.applyValue = function(item, state) {
        // deserialize the value(s) saved to "state" and apply them to the data item
        // this method may get called after the editor itself has been destroyed
        // treat it as an equivalent of a Java/C# "static" method - no instance variables should be accessed
        if (state.id === null) {
          item[column.field] = 'null';
        } else {
          item[column.field] = state.id;
        }
      };

      this.validate = function() {
        // validate user input and return the result along with the validation message, if any
        // if the input is valid, return {valid:true,msg:null}
        return {
          valid: true,
          msg: null
        };
      };

      this.getCell = function() {
        return $select.parent();
      };

      this.init();
    }

    // The editor which use jquery.chosen to allow you choose the value as select
    function SelectEditor(args) {
      var column = args.column;
      var $select, $wrapper;
      var choicesFetchPath;
      var choices = column.choices;
      var addOptionText = 'Add new Option';
      var self = this;
      var virtualGrid = {
        name: column.singular_name,
        path: '/' + column.table,
        query: "?grid=" + column.klass_name + "Grid&screen=" + column.klass_name + "Screen"
      };
      // get choices options from choices_column value
      if (!choices && column.choices_column) {
        choices = args.item[column.choices_column];
      }
      // if the choices option is an array, construce an select option for each element
      if ($.isArray(choices)) {
        choicesFetchPath = $.map(choices, function(e, index) {
          if ($.isPlainObject(e)) {
            return e;
          } else {
            return {
              id: e,
              name: e
            };
          }
        });
      } else if ($.isPlainObject(choices)) { // else if it is an object, construct a more complex object containing select options
        choicesFetchPath = {};
        for (var i in choices) {
          if ($.isEmptyObject(choices[i])) {
            choicesFetchPath[i] = [];
          } else {
            var option = $.map(choices[i], function(e, index) {
              return {
                id: e,
                name: e
              };
            });
            choicesFetchPath[i] = option;
          }
        }
      }

      var dependColumn = column.depend_column;
      var defaultValue;
      var originColumn;
      for (var k in args.grid.originColumns) {
        if (args.grid.originColumns[k].name == column.name) {
          originColumn = args.grid.originColumns[k];
          break;
        }
      }

      var boxWidth = (column.width < originColumn.width) ? originColumn.width : column.width;
      var offsetWith = boxWidth + 28;

      this.init = function() {
        $wrapper = $("<DIV style='z-index:10000;position:absolute;background:white;padding:3px;margin:-3px 0 0 -7px;border:3px solid gray; -moz-border-radius:10px; border-radius:10px;'/>")
          .appendTo(args.container);
        $select = $("<select class='chzn-select' style='width:" + boxWidth + "px'></select>")
          .appendTo($wrapper);
        $select.focus();
        var winWith = $(window).width(),
          offsetLeft = $wrapper.offset().left;
        if (winWith - offsetLeft < offsetWith) {
          $wrapper.offset({
            left: winWith - offsetWith
          });
        }

        // if it depend on other column's value, filter the choices
        if (dependColumn) {
          var dependValue = args.item[dependColumn];
          choicesFetchPath = choicesFetchPath[dependValue];
          if (!$.isArray(choicesFetchPath) || choicesFetchPath.length === 0) {
            // TODO: maybe need to disable the editor?
            //return false;
          }
        }

        // must append the current value option, otherwise this.serializeValue can't get it
        $select.append($("<option />"));

        //$select.append("<option style='color:red;' value=''>Set Blank</option>");
        if (args.item[column.field]) {
          if (typeof(args.item[column.field]) == "string") {
            $select.append("<option style='display: none;' value='" + args.item[column.field] + "'>" + args.item[column.field] + "</option>");
            $select.val(args.item[column.field]);
          } else if (args.item[column.field].id) {
            $select.append("<option style='display: none;' value='" + args.item[column.field].id + "'>" + args.item[column.field][optionTextAttribute] + "</option>");
            $select.val(args.item[column.field].id);
          }
        }

        if ($.isArray(choicesFetchPath)) {
          var arrOptions = [];
          $.each(choicesFetchPath, function(index, value) {
            if (!args.item[column.field] || args.item[column.field].id != value.id)
              arrOptions.push("<option value='" + value.id + "'>" + value.name + "</option>");
          });
          $select.append(arrOptions.join(''));
          $select.chosen({
            search_contains: true,
            allow_single_deselect: !args.column['required']
          });
        } else {
          self.getOptions();
        }

        // Open drop-down
        setTimeout(function() {
          $select.trigger('liszt:open');
        }, 300);
      };

      this.getOptions = function(selectedId, theCurrentValue) {
        $.getJSON(choicesFetchPath, function(itemdata) {
          var ajaxOptions = [];
          $.each(itemdata, function(index, value) {
            if (!args.item[column.field] || args.item[column.field].id != value.id)
              ajaxOptions.push("<option value='" + value.id + "'>" + value[optionTextAttribute] + "</option>");
          });
          $select.append(ajaxOptions.join(''));

          if (column.dynamic_options) {
            $select.append('<option>' + addOptionText + '</option>');
          }

          $select.chosen({
            search_contains: true,
            allow_single_deselect: !args.column['required']
          });

          // Update theCurrentValue
          $select.chosen().change(function() {
            theCurrentValue = $select.val();
          });
          theCurrentValue = $select.val();

          // 'Add new option' option handler
          $('#' + $select.attr('id') + '_chzn li:contains("' + addOptionText + '")').off('mouseup').on('mouseup', function(event) {
            event.preventDefault();
            Ui.openModal(virtualGrid, 'wulin_master_option_new_form', null, function() {
              // register 'Create' button click event, need to remove to modal action later
              $('#' + virtualGrid.name + '_option_submit').off('click').on('click', function(e) {
                e.preventDefault();
                Requests.createByAjax({
                  path: virtualGrid.path,
                  name: virtualGrid.name
                }, false, function(data) {
                  self.getOptions(data.id, theCurrentValue);
                  setTimeout(function() {
                    Ui.hideModal(virtualGrid.name);
                  }, 100);
                });
              });
            });
            return false;
          });
        });
      };

      this.destroy = function() {
        $wrapper.remove();
      };

      this.focus = function() {
        $select.focus();
      };

      this.isValueChanged = function() {
        // return true if the value(s) being edited by the user has/have been changed
        return ($select.val() != defaultValue);
      };

      this.serializeValue = function() {
        var obj = {
          id: $select.val()
        };
        obj.id = $select.val();
        return obj;
      };

      this.loadValue = function(item) {
        defaultValue = item[column.field];
        //if(defaultValue != "")
        $select.val(defaultValue);
        $select.select();
      };

      this.applyValue = function(item, state) {
        item[column.field] = state.id;
      };

      this.validate = function() {
        return {
          valid: true,
          msg: null
        };
      };

      this.getCell = function() {
        return $select.parent();
      };

      this.init();
    }

    function DoubleSelectEditor(args) {
      var column = args.column;
      var $from, $to;
      var scope = this;
      var originValue = args.item[column.field].split('-');
      var staticValue = originValue[2] + '-' + originValue[3];
      var from_choices = column.from_choices_path;
      var to_choices = column.to_choices_path;
      var from_field = column.from_field;
      var to_field = column.to_field;
      var defaultValue;
      var boxWidth = 200;
      var offsetWith = boxWidth * 2 + 70;
      this.init = function() {
        var $wrapper, values = args.item[column.field].split('-');
        $wrapper = $("<DIV style='z-index:10000;position:absolute;background:white;padding:3px;margin:-3px 0 0 -7px;border:3px solid gray; -moz-border-radius:10px; border-radius:10px;'/>")
          .appendTo(args.container);

        $from = $("<select class='chzn-select' style='width: " + boxWidth + "px;'></select>").appendTo($wrapper);
        $wrapper.append("&nbsp; <span>-</span> &nbsp;");
        $to = $("<select class='chzn-select' style='width: " + boxWidth + "px;'></select>").appendTo($wrapper);
        $wrapper.append(' <span>-' + staticValue + '</span>');

        $from.append($("<option />"));
        $to.append($("<option />"));
        // Append from select options
        if ($.isArray(from_choices)) {
          $.each(from_choices, function(index, value) {
            $from.append("<option value='" + value.id + "' code='" + value.code + "'>" + value.name + "</option>");
          });
          $('option[code="' + values[0] + '"]', $from).attr("selected", "selected");
          $from.chosen({
            search_contains: true,
            allow_single_deselect: !args.column['required']
          });
        } else {
          $.getJSON(from_choices, function(itemdata) {
            $.each(itemdata, function(index, value) {
              $from.append("<option value='" + value.id + "' code='" + value.code + "'>" + value.name + "</option>");
            });
            $('option[code="' + values[0] + '"]', $from).attr("selected", "selected");
            $from.chosen({
              search_contains: true,
              allow_single_deselect: !args.column['required']
            });
          });
        }
        // Append to select options
        if ($.isArray(to_choices)) {
          $.each(to_choices, function(index, value) {
            $to.append("<option value='" + value.id + "' code='" + value.code + "'>" + value.name + "</option>");
          });
          $('option[code="' + values[1] + '"]', $to).attr("selected", "selected");
          $to.chosen({
            search_contains: true,
            allow_single_deselect: !args.column['required']
          });
        } else {
          $.getJSON(to_choices, function(itemdata) {
            $.each(itemdata, function(index, value) {
              $to.append("<option value='" + value.id + "' code='" + value.code + "'>" + value.name + "</option>");
            });
            $('option[code="' + values[1] + '"]', $to).attr("selected", "selected");
            $to.chosen({
              search_contains: true,
              allow_single_deselect: !args.column['required']
            });
          });
        }
        scope.focus();
        // Open drop-down
        setTimeout(function() {
          $select.trigger('liszt:open');
        }, 300);

        var winWith = $(window).width(),
          offsetLeft = $wrapper.offset().left;
        if (winWith - offsetLeft < offsetWith) {
          $wrapper.offset({
            left: winWith - offsetWith
          });
        }
      };

      this.destroy = function() {
        $(args.container).empty();
      };

      this.focus = function() {
        $from.focus();
      };

      this.serializeValue = function() {
        var stateH = {};
        stateH[from_field + '_value'] = $from.val();
        stateH[to_field + '_value'] = $to.val();
        stateH[from_field + '_code'] = $('option:selected', $from).attr('code');
        stateH[to_field + '_code'] = $('option:selected', $to).attr('code');
        stateH[from_field + '_text'] = $('option:selected', $from).text();
        stateH[to_field + '_text'] = $('option:selected', $to).text();
        return stateH;
      };

      this.applyValue = function(item, state) {
        item[from_field] = state[from_field + '_value'];
        item[to_field] = state[to_field + '_value'];
        item[column.field] = state[from_field + '_code'] + '-' + state[to_field + '_code'] + '-' + staticValue;
      };

      this.loadValue = function(item) {
        defaultValue = item[column.field].split('-');
        $('option[code="' + defaultValue[0] + '"]', $from).attr("selected", "selected");
        $('option[code="' + defaultValue[1] + '"]', $to).attr("selected", "selected");
      };

      this.isValueChanged = function() {
        var currentFromValue = $('option:selected', $from).attr('code'),
          currentToValue = $('option:selected', $to).attr('code');
        return defaultValue[0] != currentFromValue || defaultValue[1] != currentToValue;
      };

      this.validate = function() {
        return {
          valid: true,
          msg: null
        };
      };

      this.getCell = function() {
        return $from.parent();
      };

      this.init();
    }

    // The editor which use jquery.chosen to allow you inputting multiple values that belongs to a record
    function DistinctEditor(args) {
      var column = args.column;
      var $select, $wrapper;
      var choicesFetchPath = column.choices;
      var optionTextAttribute = column.optionTextAttribute || 'name';
      var defaultValue;
      var originColumn;
      var addOptionText = 'Add new Option';
      var bottomOption = '<option>' + addOptionText + '</option>';
      var self = this;
      for (var i in args.grid.originColumns) {
        if (args.grid.originColumns[i].name == column.name) {
          originColumn = args.grid.originColumns[i];
          break;
        }
      }
      var boxWidth = (column.width < originColumn.width) ? originColumn.width : column.width;
      var offsetWith = boxWidth + 28;

      this.init = function() {
        $wrapper = $("<DIV style='z-index:10000;position:absolute;background:white;padding:3px;margin:-3px 0 0 -7px;border:3px solid gray; -moz-border-radius:10px; border-radius:10px;'/>")
          .appendTo(args.container);
        $select = $("<select class='chzn-select' style='width:" + boxWidth + "px'></select>");
        $select.appendTo($wrapper);
        $select.focus();
        var winWith = $(window).width(),
          offsetLeft = $wrapper.offset().left;
        if (winWith - offsetLeft < offsetWith) {
          $wrapper.offset({
            left: winWith - offsetWith
          });
        }

        // must append the current value option, otherwise this.serializeValue can't get it
        $select.append($("<option />"));
        if (args.item[column.field] && args.item[column.field].id) {
          $select.append("<option value='" + args.item[column.field].id + "'>" + args.item[column.field][optionTextAttribute] + "</option>");
          $select.val(args.item[column.field].id);
        }

        self.getOptions();

        // Open drop-down
        setTimeout(function() {
          $select.trigger('liszt:open');
        }, 300);
      };

      this.getOptions = function() {
        $.getJSON(choicesFetchPath, function(itemdata) {
          var ajaxOptions = [];
          $.each(itemdata, function(index, value) {
            ajaxOptions.push("<option value='" + value + "'>" + value + "</option>");
          });
          $select.append(ajaxOptions.join(''));

          $select.append(bottomOption);
          $select.val(args.item[column.field]);
          $select.chosen({
            search_contains: true,
            allow_single_deselect: !args.column['required']
          });
          // 'Add new option' option handler
          $('#' + $select.attr('id') + '_chzn li:contains("' + addOptionText + '")').off('mouseup').on('mouseup', function(event) {
            var $modal = $('#general_modal');

            var $fieldDiv = $("<div />").attr({
              style: 'padding: 20px 30px;'
            });
            var $submitDiv = $("<div />").attr({
              style: 'padding: 0 30px;'
            });
            $fieldDiv.append('<label for="distinct_field" style="display: inline-block; margin-right: 6px;">' + column.name + '</label>');
            $fieldDiv.append('<input id="distinct_field" type="text" style="width: 250px" size="30" name="distinct_field">');
            $fieldDiv.appendTo($modal);
            $submitDiv.append('<input id="distinct_submit" class="btn success" type="submit" value=" Add ' + column.name + ' " name="commit">');
            $submitDiv.appendTo($modal);

            var openCallback = function() {
              $('#distinct_submit', $(this)).on('click', function() {
                var optionText = $modla.find('#distinct_field').val();
                if (optionText) {
                  $('option:contains("' + addOptionText + '")', $select).before('<option value="' + optionText + '">' + optionText + '</option>');
                  $select.val(optionText);
                  $select.trigger('liszt:updated');
                  $modal.modal('hide');
                } else {
                  alert('New ' + column.name + ' can not be blank!');
                }
              });
            };

            displayGeneralMessage(openCallback, null, 'Cancel', null, null, 'Add new ' + column.name);

            return false;
          });
        });
      };

      this.destroy = function() {
        // remove all data, events & dom elements created in the constructor
        $wrapper.remove();
      };

      this.focus = function() {
        // set the focus on the main input control (if any)
        $select.focus();
      };

      this.isValueChanged = function() {
        // return true if the value(s) being edited by the user has/have been changed
        return ($select.val() != defaultValue);
      };

      this.serializeValue = function() {
        return $select.val();
      };

      this.loadValue = function(item) {
        defaultValue = item[column.field] || "";
        $select.val(defaultValue);
        $select[0].defaultValue = defaultValue;
        $select.select();
      };

      this.applyValue = function(item, state) {
        item[column.field] = state;
      };

      this.validate = function() {
        // validate user input and return the result along with the validation message, if any
        // if the input is valid, return {valid:true,msg:null}
        return {
          valid: true,
          msg: null
        };
      };

      this.getCell = function() {
        return $select.parent();
      };

      this.init();
    }

    // Usage:
    // column [:column_name], auto_complete: true
    function AutoCompleteTextEditor(args) {
      var column = args.column;
      var $input, $select, $wrapper;
      var choicesFetchPath = column.choices;
      var defaultValue;
      var self = this;
      var boxWidth = column.width + 2;
      var offsetWith = boxWidth + 18;

      this.init = function() {
        var count = 0;
        var down = true;
        $input = $("<INPUT type=text class='editor-text' style='width:" + boxWidth + "px;border:0' />")
          .appendTo(args.container)
          .bind("keydown.nav", function(e) {
            var optionLength = $(".select-option").length;
            if ((e.keyCode === $.ui.keyCode.LEFT) || ((e.keyCode === $.ui.keyCode.RIGHT))) {
              e.stopImmediatePropagation();
            } else if (e.keyCode === $.ui.keyCode.DOWN) {
              if ($(".select-option").length > 0) {
                if (down == true) {
                  if ((count > 0) && (count < $(".select-option").length)) {
                    $(".select-option:eq(" + (count - 1) + ")").removeClass("blue-background");
                  }
                  $(".select-option:eq(" + count + ")").addClass("blue-background");
                } else {
                  $(".select-option:eq(" + count + ")").removeClass("blue-background");
                  $(".select-option:eq(" + (count + 1) + ")").addClass("blue-background");
                  count++;
                  down = true;
                }
                count++;
                if (count > $(".select-option").length) {
                  count = $(".select-option").length;
                }
              }
            } else if (e.keyCode === $.ui.keyCode.UP) {
              if ($(".select-option").length > 0) {
                if (down == true) {
                  count--;
                  down = false;
                }
                if (count > 0) {
                  if (count == $(".select-option").length) {
                    $(".select-option:eq(" + (count - 1) + ")").removeClass("blue-background");
                    $(".select-option:eq(" + (count - 2) + ")").addClass("blue-background");
                  } else {
                    $(".select-option:eq(" + count + ")").removeClass("blue-background");
                    $(".select-option:eq(" + (count - 1) + ")").addClass("blue-background");
                  }
                }
                count--;
                if (count < 0) {
                  count = 0;
                }
              }
            }
          })
          .bind("keydown", function(event) {
            if (event.keyCode == "13") {
              var value = $(".select-option.blue-background").text();
              if (value != "") {
                self.setValue(value);
              } else {
                self.setValue($input.val());
              }
              $(".wrapper").remove();
            }
          })
          .bind("input", function() {
            var value = self.getValue();
            self.getOptions(value);
            down = true;
            count = 0;
          })
          .scrollLeft(0)
          .focus();
      };

      this.getOptions = function(input) {
        if ($(".select-option").length > 0) {
          $(".select-option").remove();
        }
        if (input == "") {
          if ($(".auto-complete-select").length > 0) {
            $(".auto-complete-select").remove();
          }
          return false;
        }
        $wrapper = $("<DIV class='wrapper' style='z-index:10000;position:absolute;padding:2px;margin:2px 0 0 -2px;width:0;height:0;border:0px solid gray; -moz-border-radius:6px; border-radius:6px;'/>");
        $select = $("<div class='auto-complete-select' style='width:" + boxWidth + "px;margin: 0px -4px -2px -5px;'><ul class='select-options' style='padding:1px;list-style:none;'></ul></div>")
          .appendTo($wrapper);
        var winWith = $(window).width(),
          offsetLeft = $wrapper.offset().left;
        if (winWith - offsetLeft < offsetWith) {
          $wrapper.offset({
            left: winWith - offsetWith
          });
        }

        choicesFetchPath += "&query_prefix=" + input;
        $.getJSON(choicesFetchPath, function(data) {
          var itemdata = [];
          $.each(data, function(index, value) {
            if (value.toLowerCase().indexOf(input.toLowerCase()) == 0) {
              itemdata.push(value);
            }
          })
          var ajaxOptions = [];
          $.each(itemdata, function(index, value) {
            if (index % 2 == 0) {
              ajaxOptions.push("<li class='select-option even' value='" + value + "'>" + value + "</li>");
            } else {
              ajaxOptions.push("<li class='select-option odd' value='" + value + "'>" + value + "</li>");
            }
          });
          $(".wrapper").remove();
          $wrapper.appendTo(args.container);
          if (ajaxOptions.length == 0) {
            $(".auto-complete-select").remove();
          }

          $(".select-options")
            .css({
              "background": "white",
              "border": "1px solid gray",
              "margin": "-1px -1px 0px 3px",
              "overflow": "auto"
            })
            .append(ajaxOptions.join(''));

          $(".select-option")
            .bind("mouseover", function() {
              $(this).addClass("blue-background");
            })
            .bind("mouseout", function() {
              $(this).removeClass("blue-background");
            })
            .click(function(event) {
              var value = event.currentTarget.textContent;
              self.setValue(value);
              $(".wrapper").remove();
            });
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
        // defaultValue = defaultValue.replace(/&amp;/g, '&');
        // defaultValue = defaultValue.replace(/&gt;/g, '>');
        // defaultValue = defaultValue.replace(/&lt;/g, '<');
        // defaultValue = defaultValue.replace(/&quot;/g, '"');
        $input.val(defaultValue);
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
        if (column.validator) {
          var validationResults = column.validator($input.val());
          if (!validationResults.valid)
            return validationResults;
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

    // Usage: column [:column_name], auto_complete: true
    function AutoCompleteTextForFormEditor(args) {
      var column = args.column;
      var $input, $select, $wrapper;
      var choicesFetchPath = column.choices;
      var defaultValue;
      var self = this;
      var boxWidth = column.width + 10;
      var offsetWith = boxWidth + 18;

      this.init = function() {
        var count = 0;
        var down = true;
        $input = args.container;

        $input.bind("input", function() {
            var value = self.getValue();
            self.getOptions(value);
            down = true;
            count = 0;
          })
          .bind("blur", function(e) {
            $(".wrapper").remove();
          })
          .scrollLeft(0)
          .focus();
      };

      this.getOptions = function(input) {
        if ($(".select-option").length > 0) {
          $(".select-option").remove();
        }
        if (input == "") {
          if ($(".auto-complete-select").length > 0) {
            $(".auto-complete-select").remove();
          }
          return false;
        }
        $wrapper = $("<DIV class='wrapper' style='z-index:10000;position:absolute;padding:2px;margin:-3px 0 0 128px;width:0;height:0;border:0px solid gray; -moz-border-radius:6px; border-radius:6px;'/>");
        $select = $("<div class='auto-complete-select' style='width:" + boxWidth + "px;margin: 0px -4px -2px -5px;'><ul class='select-options' style='padding:3px;list-style:none;'></ul></div>")
          .appendTo($wrapper);
        var winWith = $(window).width(),
          offsetLeft = $wrapper.offset().left;
        if (winWith - offsetLeft < offsetWith) {
          $wrapper.offset({
            left: winWith - offsetWith
          });
        }

        $.getJSON(choicesFetchPath, function(data) {
          var itemdata = [];
          $.each(data, function(index, value) {
            if (value.toLowerCase().indexOf(input.toLowerCase()) == 0) {
              itemdata.push(value);
            }
          })
          var ajaxOptions = [];
          $.each(itemdata, function(index, value) {
            if (index % 2 == 0) {
              ajaxOptions.push("<li class='select-option even' value='" + value + "'>" + value + "</li>");
            } else {
              ajaxOptions.push("<li class='select-option odd' value='" + value + "'>" + value + "</li>");
            }
          });
          $(".wrapper").remove();
          $wrapper.insertAfter($input);
          if (ajaxOptions.length == 0) {
            $(".auto-complete-select").remove();
          }

          $(".select-options")
            .css({
              "background": "white",
              "border": "1px solid gray",
              "margin": "-1px -1px 0px 3px",
              "max-height": "220px",
              "overflow": "auto"
            })
            .append(ajaxOptions.join(''));

          $(".select-option")
            .bind("mouseover", function() {
              $(this).addClass("blue-background");
            })
            .bind("mouseout", function() {
              $(this).removeClass("blue-background");
            })
            .click(function(event) {
              var value = event.currentTarget.textContent;
              self.setValue(value);
              $(".wrapper").remove();
            });
        });
      };

      this.getValue = function() {
        return $input.val();
      };

      this.setValue = function(val) {
        $input.val(val);
      };

      this.init();
    }
})(jQuery);