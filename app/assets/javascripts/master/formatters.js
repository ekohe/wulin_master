(function($) {
  var SlickFormatter = {

    ///////////////////////////////////////////////////////////////////////////
    // Helpers
    ///////////////////////////////////////////////////////////////////////////

    ApplyStyle: function(value, style) {
      return value === null ? "" : "<span style='" + style + ";display:block'>" + value + "</span>";;
    },

    ///////////////////////////////////////////////////////////////////////////
    // Tested Formatter
    ///////////////////////////////////////////////////////////////////////////

    BaseFormatter: function(row, cell, value, columnDef, dataContext) {
      var optionTextAttribute = columnDef.optionTextAttribute;
      var inner_formatter = columnDef.inner_formatter;

      // Retrive info for relation columns
      if (optionTextAttribute) {
        value = value[optionTextAttribute];
      }

      // Apply format for relation columns
      if (inner_formatter) {
        if (inner_formatter == 'boolean') {
          value = TextBoolCellFormatter(row, cell, eval(value), columnDef, dataContext);
        } else if (typeof(window[inner_formatter]) == 'function') {
          value = window[inner_formatter](row, cell, value, columnDef, dataContext);
        }
      }

      // Apply style
      return ApplyStyle(value, columnDef.style);
    },

    MoneyFormatter: function(row, cell, value, columnDef, dataContext) {
      var currency = columnDef.currency || "$";
      var text = (value === null || value === undefined || value === '') ? '' : parseFloat(value).toMoney(2, '.', ',') + ' ' + currency;
      return ApplyStyle(text, columnDef.style);
    },

    TextBoolCellFormatter: function(row, cell, value, columnDef, dataContext) {
      var text = value === null ? "" : (value ? 'Yes' : 'No');
      return ApplyStyle(text, columnDef.style);
    },

    GraphicBoolCellFormatter: function(row, cell, value, columnDef, dataContext) {
      var html = value ? "<img src='/assets/tick.png'>" : "";
      return ApplyStyle(html, columnDef.style);
    },

    ZeroFormatter: function(row, cell, value, columnDef, dataContext) {
      var text = value === 0 ? "" : value;
      return ApplyStyle(text, columnDef.style);
    },

    TooltipFormatter: function(row, cell, value, columnDef, dataContext) {
      return "<div title='" + columnDef.tooltips[value] + "'>" + ApplyStyle(value, columnDef.style) + "</div>";
    },

    ///////////////////////////////////////////////////////////////////////////
    // Existing (Not tested yet)
    ///////////////////////////////////////////////////////////////////////////

    // Date cell formatter to handle "yy-mm-dd" format (for StandardDateCellEditor)
    StandardDateCellFormatter: function(row, cell, value, columnDef, dataContext) {
      if (value === null || value === "") {
        return "";
      }
      value = value.split(/\s+/)[0];

      if (/^\d{4}(\-|\/|\.)\d{1,2}\1\d{1,2}$/.test(value)) {
        var thedate = $.datepicker.parseDate("yy-mm-dd", value);
        return $.datepicker.formatDate(columnDef.DateShowFormat, thedate);
      } else {
        return value;
      }
    },

    // Simple data formatter,display a date as "dd mmm" format, like "21 dec"
    OnlyDateFormatter: function(row, cell, value, columnDef, dataContext) {
      if (value === null || value === "") {
        return "";
      } else if ($.isPlainObject(value)) {
        value = value[columnDef.optionTextAttribute];
      }

      if (/^\d{4}(\-|\/|\.)\d{1,2}\1\d{1,2}(\s\d{1,2}:\d{1,2})?$/.test(value)) {
        var thedate = $.datepicker.parseDate("yy-mm-dd", value);
        return thedate.format("yyyy-mm-dd");
      } else {
        return value;
      }
    },

    // Simple data formatter,display a date as "dd mmm" format, like "21 dec"
    SimpleDateFormatter: function(row, cell, value, columnDef, dataContext) {
      if (value === null || value === "") {
        return "";
      } else if ($.isPlainObject(value)) {
        value = value[columnDef.optionTextAttribute];
      }

      if (/^\d{4}(\-|\/|\.)\d{1,2}\1\d{1,2}(\s\d{1,2}:\d{1,2})?$/.test(value)) {
        var thedate = $.datepicker.parseDate("yy-mm-dd", value);
        return thedate.format("dd mmm");
      } else {
        return value;
      }
    },

    SimpleTimeFormatter: function(row, cell, value, columnDef, dataContext) {
      var timeArr;
      if (value === null || value === "") {
        return "";
      } else if ($.isPlainObject(value)) {
        value = value[columnDef.optionTextAttribute];
      }

      if (/^(\d{4}(\-|\/|\.)\d{1,2}(\-|\/|\.)\d{1,2}\s)?\d{1,2}:\d{1,2}$/.test(value)) {
        timeArr = value.split(/\s/);
        return timeArr[timeArr.length - 1];
      } else {
        return value;
      }
    },

    // Helpers for simple time/date to support for date format as "12 May/12May", and time format as "12:12/1212"
    ParseSimpleTime: function(simpleTimeStr) {
      try {
        var matchedArr = simpleTimeStr.match(/^(\d{2}):?(\d{2})$/);
        return $.datepicker.parseTime("hh:mm", matchedArr[1] + ":" + matchedArr[2]);
      } catch (err) {
        return null;
      }
    },

    ParseSimpleDate: function(simpleDateStr) {
      try {
        var matchedArr = simpleDateStr.match(/^(\d{2})\s?([A-Za-z]{3})$/);
        return $.datepicker.parseDate("dd M", matchedArr[1] + " " + matchedArr[2]);
      } catch (err) {
        return null;
      }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Removed (Not using after refactoring; For style & relation columns)
    ///////////////////////////////////////////////////////////////////////////

    // RightFormatter: function(row, cell, value, columnDef, dataContext) {
    //   return value === null ? "" : "<span style='text-align:right;display:block'>" + value + "</span>";
    // },

    // CenterFormatter: function(row, cell, value, columnDef, dataContext) {
    //   return value === null ? "" : "<span style='text-align:center;display:block'>" + value + "</span>";
    // },

    // BelongsToFormatter: function(row, cell, value, columnDef, dataContext) {
    //   value = value[columnDef.optionTextAttribute];
    //   if (!columnDef.inner_formatter) return value;
    //
    //   // if has inner_formatter
    //   if (columnDef.inner_formatter == 'boolean') {
    //     return TextBoolCellFormatter(row, cell, eval(value), columnDef, dataContext);
    //   } else if (typeof(window[columnDef.inner_formatter]) == 'function') {
    //     return window[columnDef.inner_formatter](row, cell, value, columnDef, dataContext);
    //   } else {
    //     return value;
    //   }
    // },

    // HasManyFormatter: function(row, cell, value, columnDef, dataContext) {
    //   return BelongsToFormatter(row, cell, value, columnDef, dataContext);
    // },

    // HasOneFormatter: function(row, cell, value, columnDef, dataContext) {
    //   return BelongsToFormatter(row, cell, value, columnDef, dataContext);
    // },

    ///////////////////////////////////////////////////////////////////////////
    // Not in Use (bss, terra_nova, mrldb, crewlist, mima)
    ///////////////////////////////////////////////////////////////////////////

    // RawFormatter: function(row, cell, value, columnDef, dataContext) {
    //   return (value === null) ? "" : value;
    // },

    // SelectorCellFormatter: function(row, cell, value, columnDef, dataContext) {
    //   return (!dataContext ? "" : row);
    // },

    // YesNoCellFormatter: function(row, cell, value, columnDef, dataContext) {
    //   return value ? "Yes" : "No";
    // },

    // NeutralMoneyFormatter: function(row, cell, value, columnDef, dataContext) {
    //   // TODO: make the unit configurable
    //   //var currency = "";
    //   var text = (value === null || value === undefined || value === '') ? '' : parseFloat(value).toMoney(2, '.', ',') ;
    //   return "<span style='text-align:right;display:block'>" + text + "</span>";
    // },

    // StarFormatter: function(row, cell, value, columnDef, dataContext) {
    //   return (value) ? "<img src='../images/bullet_star.png' align='absmiddle'>" : "";
    // },

    // Simple data formatter,display a date as "MM" format, like "December"
    // SimpleMonthFormatter: function(row, cell, value, columnDef, dataContext) {
    //   if (value === null || value === "") {
    //     return "";
    //   } else if ($.isPlainObject(value)) {
    //     value = value[columnDef.optionTextAttribute];
    //   }
    //
    //   if (/^\d{4}(\-|\/|\.)\d{1,2}\1\d{1,2}(\s\d{1,2}:\d{1,2})?$/.test(value)) {
    //     var thedate = $.datepicker.parseDate("yy-mm-dd", value);
    //     return "<span style='text-align:right;display:block'>" + $.datepicker.formatDate(columnDef.DateShowFormat, thedate) + "</span>";
    //   } else {
    //     return "<span style='text-align:right;display:block'>" + value + "</span>";
    //   }
    // },

  };

  $.extend(window, SlickFormatter);

})(jQuery);
