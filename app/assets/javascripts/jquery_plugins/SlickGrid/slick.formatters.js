/***
 * Contains basic SlickGrid formatters.
 *
 * NOTE:  These are merely examples.  You will most likely need to implement something more
 *        robust/extensible/localizable/etc. for your use!
 *
 * @module Formatters
 * @namespace Slick
 */

(function ($) {
  // register namespace
  $.extend(true, window, {
    "Slick": {
      "Formatters": {
        "PercentComplete": PercentCompleteFormatter,
        "PercentCompleteBar": PercentCompleteBarFormatter,
        "YesNo": YesNoFormatter,
        "Checkmark": CheckmarkFormatter,
        "Raw": RawFormatter,
        "Tooltip": TooltipFormatter,
        "SelectorCell": SelectorCellFormatter,
        "YesNoCell": YesNoCellFormatter,
        "GraphicBoolCell": GraphicBoolCellFormatter,
        "TextBoolCell": TextBoolCellFormatter,
        "Money": MoneyFormatter,
        "Right": RightFormatter,
        "Center": CenterFormatter,
        "Star": StarFormatter,
        "StandardDateCell": StandardDateCellFormatter,
        "OnlyDate": OnlyDateFormatter,
        "SimpleDate": SimpleDateFormatter,
        "SimpleTime": SimpleTimeFormatter,
        "BelongsTo": BelongsToFormatter,
        "HasMany": HasManyFormatter,
        "HasOne": HasOneFormatter,
        "ParseS": ParseSimpleTime,
        "ParseS": ParseSimpleDate,
        "Zero": ZeroFormatter
      }
    }
  });

  function PercentCompleteFormatter(row, cell, value, columnDef, dataContext) {
    if (value == null || value === "") {
      return "-";
    } else if (value < 50) {
      return "<span style='color:red;font-weight:bold;'>" + value + "%</span>";
    } else {
      return "<span style='color:green'>" + value + "%</span>";
    }
  }

  function PercentCompleteBarFormatter(row, cell, value, columnDef, dataContext) {
    if (value == null || value === "") {
      return "";
    }

    var color;

    if (value < 30) {
      color = "red";
    } else if (value < 70) {
      color = "silver";
    } else {
      color = "green";
    }

    return "<span class='percent-complete-bar' style='background:" + color + ";width:" + value + "%'></span>";
  }

  function YesNoFormatter(row, cell, value, columnDef, dataContext) {
    return value ? "Yes" : "No";
  }

  function CheckmarkFormatter(row, cell, value, columnDef, dataContext) {
    return value ? "<span class='tick'></span>" : "";
  }

  function RawFormatter(row, cell, value, columnDef, dataContext) {
    return (value === null) ? "" : value;
  }

  function TooltipFormatter(row, cell, value, columnDef, dataContext) {
    return "<div title='" + columnDef.tooltips[value] + "'>" + "<span style='text-align:center;display:block'>" + value + "</span></div>";
  }

  function SelectorCellFormatter(row, cell, value, columnDef, dataContext) {
    return (!dataContext ? "" : row);
  }

  function YesNoCellFormatter(row, cell, value, columnDef, dataContext) {
    return value ? "Yes" : "No";
  }

  function GraphicBoolCellFormatter(row, cell, value, columnDef, dataContext) {
    return value ? "<span class='tick'></span>" : "";
  }

  function TextBoolCellFormatter(row, cell, value, columnDef, dataContext) {
    return value === null ? "" : (value ? 'Yes' : 'No');
  }

  function MoneyFormatter(row, cell, value, columnDef, dataContext) {
    // TODO: make the unit configurable
    var currency = columnDef.currency || "$";
    var text = (value === null || value === undefined || value === '') ? '' : parseFloat(value).toMoney(2, '.', ',') + ' ' + currency;
    return "<span style='text-align:right;display:block'>" + text + "</span>";
  }

  function RightFormatter(row, cell, value, columnDef, dataContext) {
    return value === null ? "" : "<span style='text-align:right;display:block'>" + value + "</span>";
  }

  function CenterFormatter(row, cell, value, columnDef, dataContext) {
    return value === null ? "" : "<span style='text-align:center;display:block'>" + value + "</span>";
  }

  function StarFormatter(row, cell, value, columnDef, dataContext) {
    return (value) ? "<img src='../images/bullet_star.png' align='absmiddle'>" : "";
  }

  // Date cell formatter to handle "yy-mm-dd" format (for StandardDateEditor)
  function StandardDateCellFormatter(row, cell, value, columnDef, dataContext) {
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
  }

  // Simple data formatter,display a date as "dd mmm" format, like "21 dec"
  function OnlyDateFormatter(row, cell, value, columnDef, dataContext) {
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
  }

  // Simple data formatter,display a date as "dd mmm" format, like "21 dec"
  function SimpleDateFormatter(row, cell, value, columnDef, dataContext) {
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
  }

  function SimpleTimeFormatter(row, cell, value, columnDef, dataContext) {
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
  }

  function BelongsToFormatter(row, cell, value, columnDef, dataContext) {
    value = value[columnDef.optionTextAttribute];
    if (!columnDef.inner_formatter) return value;

    // if has inner_formatter
    if (columnDef.inner_formatter == 'boolean') {
      return TextBoolCellFormatter(row, cell, eval(value), columnDef, dataContext);
    } else if (typeof(window[columnDef.inner_formatter]) == 'function') {
      return window[columnDef.inner_formatter](row, cell, value, columnDef, dataContext);
    } else {
      return value;
    }
  }

  function HasManyFormatter(row, cell, value, columnDef, dataContext) {
    return BelongsToFormatter(row, cell, value, columnDef, dataContext);
  }

  function HasOneFormatter(row, cell, value, columnDef, dataContext) {
    return BelongsToFormatter(row, cell, value, columnDef, dataContext);
  }

  // Helpers for simple time/date to support for date format as "12 May/12May", and time format as "12:12/1212"
  function ParseSimpleTime(simpleTimeStr) {
    try {
      var matchedArr = simpleTimeStr.match(/^(\d{2}):?(\d{2})$/);
      return $.datepicker.parseTime("hh:mm", matchedArr[1] + ":" + matchedArr[2]);
    } catch (err) {
      return null;
    }
  }

  function ParseSimpleDate(simpleDateStr) {
    try {
      var matchedArr = simpleDateStr.match(/^(\d{2})\s?([A-Za-z]{3})$/);
      return $.datepicker.parseDate("dd M", matchedArr[1] + " " + matchedArr[2]);
    } catch (err) {
      return null;
    }
  }

  function ZeroFormatter(row, cell, value, columnDef, dataContext) {
    return value === 0 ? "" : "<span style='text-align:right;display:block'>" + value + "</span>";
  }
})(jQuery);