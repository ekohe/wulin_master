(function($) {

  var SlickFormatter = {

    ///////////////////////////////////////////////////////////////////////////
    // Helpers
    ///////////////////////////////////////////////////////////////////////////

    applyStyle: function(value, styleClass = '', style = '') {
      return value === null ? "" : "<span class='" + styleClass + "' style='" + style + ";display:block'>" + value + "</span>";
    },

    parseDateTime: function(dateTimeStr) {
      try {
        var REGEX_DATE = '(\\d{2})\\/(\\d{2})\\/(\\d{4})'; // 'yyyy-mm-dd'
        var REGEX_TIME = '(\\d{2}):(\\d{2})'; // 'hh:mm'
        var matchedArr = dateTimeStr.match(new RegExp('^' + REGEX_DATE + '[ \\t]' + REGEX_TIME + '$'));

        return {
          day: matchedArr[1],
          month: matchedArr[2],
          year: matchedArr[3],
          hour: matchedArr[4],
          minute: matchedArr[5]
        };
      } catch (err) {
        return null;
      }
    },

    ///////////////////////////////////////////////////////////////////////////
    // Formatters
    ///////////////////////////////////////////////////////////////////////////

    BaseFormatter: function(row, cell, value, columnDef, dataContext) {
      var source = columnDef.source;
      var inner_formatter = columnDef.inner_formatter;

      // Retrive info for relation columns
      if (source && typeof value === 'object') {
        value = value[source];
      }

      // Apply format for relation columns
      if (inner_formatter) {
        if (inner_formatter == 'boolean') {
          value = TextBoolCellFormatter(row, cell, eval(value), columnDef, dataContext);
        } else if (typeof(window[inner_formatter]) == 'function') {
          value = window[inner_formatter](row, cell, value, columnDef, dataContext);
        }
      }

      // Filter `null` value for 'has_many' columns
      value = (columnDef.type === 'has_many' && value === 'null') ? '' : value;

      // Set default text-align
      var textAlign, default_style;
      if (columnDef.type == 'datetime' ||
        columnDef.type == 'date' ||
        columnDef.type == 'time') {
        textAlign = 'center';
      }
      default_style = textAlign ? 'text-align:' + textAlign : ''

      // Apply style
      return applyStyle(value, columnDef.style_class, columnDef.style || default_style);
    },

    MoneyFormatter: function(row, cell, value, columnDef, dataContext) {
      var currency = columnDef.currency || "$";
      var text = (value === null || value === undefined || value === '') ? '' : parseFloat(value).toMoney(2, '.', ',') + ' ' + currency;
      return applyStyle(text, columnDef.style_class, columnDef.style || 'text-align:right');
    },

    TextBoolCellFormatter: function(row, cell, value, columnDef, dataContext) {
      var text = value === null ? "" : (value ? 'Yes' : 'No');
      return applyStyle(text, columnDef.style_class, columnDef.style || 'text-align:center');
    },

    GraphicBoolCellFormatter: function(row, cell, value, columnDef, dataContext) {
      var checked = value ? 'checked="checked"' : '';
      var html = '<input disabled type="checkbox" class="filled-in" ' +
        checked + ' id="show-checkbox-' + row + '" />' +
        '<label for="show-checkbox-' + row +
        '"></label>';
      return applyStyle(html, columnDef.style_class, columnDef.style || 'text-align:center');
    },

    ZeroFormatter: function(row, cell, value, columnDef, dataContext) {
      var text = value === 0 ? "" : value;
      return applyStyle(text, columnDef.style_class, columnDef.style || 'text-align:right');
    },

    TooltipFormatter: function(row, cell, value, columnDef, dataContext) {
      return "<div title='" + columnDef.tooltips[value] + "'>" + applyStyle(value, columnDef.style_class, columnDef.style || 'text-align:center') + "</div>";
    },

    // Support image tag on grid
    ImageFormatter: function(row, cell, value, columnDef, dataContext) {
      if (value == null) { return ""; }

      var style = columnDef.style || 'text-align:center';
      return "<div style='" + style + "'><img src='" + value + "' /></div>";
    }
  };

  $.extend(window, SlickFormatter);

})(jQuery);
