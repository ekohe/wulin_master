(function($) {

  var SlickFormatter = {

    ///////////////////////////////////////////////////////////////////////////
    // Helpers
    ///////////////////////////////////////////////////////////////////////////

    applyStyle: function(node, styleClass, style) {
      if (node === null) { return ''; }

      if (typeof node === 'string' || node instanceof String) {
        node = document.createTextNode(node);
      }

      var span = document.createElement('span');

      if (styleClass!=null) {
        span.setAttribute('class', styleClass);
      }
      if ((style !== null) && (style !== '')) {
        span.setAttribute('style', style);
      }

      span.append(node)
      return span.outerHTML;
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
      if (source && value && typeof value === 'object') {
        value = value[source];
      }

      // Apply format for relation columns
      if (inner_formatter) {
        if (inner_formatter == 'boolean') {
          return TextBoolCellFormatter(row, cell, eval(value), columnDef, dataContext);
        } else if (typeof(window[inner_formatter]) == 'function') {
          return window[inner_formatter](row, cell, value, columnDef, dataContext);
        }
      }

      // Filter `null` value for 'has_many' columns
      value = (columnDef.type === 'has_many' && value === 'null') ? '' : value;

      // Apply Format based on value type
      if ($.isArray(value)) {
        // Convert Array to String for present in Grid Cell
        // Example of default delimiter: ['one', 'two', 'three', ['four']] => 'one, two, three, four'
        var delimiter = columnDef.delimiter || ', ';
        value = value.join().replace(/\,(?=[^\s])/g, delimiter);
      }

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

    NumberWithDelimiterFormatter: function(row, cell, value, columnDef, dataContext) {
      if (columnDef.precision == undefined) {
        var precision = 0;
      } else {
        var precision = columnDef.precision;
      }

      if (value === null || value === undefined || value === '') {
        var text = '';
      } else {
        if (precision == 0){
          var text = parseInt(value).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        } else {
          var text = parseFloat(value).toFixed(precision).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        }
      }
      return applyStyle(text, columnDef.style_class, columnDef.style || '');
    },

    MoneyFormatter: function(row, cell, value, columnDef, dataContext) {
      var currency = columnDef.currency || "$";
      if (columnDef.precision == undefined) {
        var precision = 2;
      } else {
        var precision = columnDef.precision;
      }

      var text = (value === null || value === undefined || value === '') ? '' : parseFloat(value).toMoney(precision, '.', ',')
      if (text !== '') {
        text = (columnDef.position_of_currency === 'before' ? currency + ' ' + text : text + ' ' + currency);
      }
      return applyStyle(text, columnDef.style_class, columnDef.style || '');
    },

    TextBoolCellFormatter: function(row, cell, value, columnDef, dataContext) {
      var text = value === null ? "" : (value ? 'Yes' : 'No');
      return applyStyle(text, columnDef.style_class, columnDef.style || 'text-align:center');
    },

    GraphicBoolCellFormatter: function(row, cell, value, columnDef, dataContext) {
      if (!value) { return ''; }

      var label = document.createElement('label');
      label.setAttribute('style', 'text-align: center; display: inline-block;');

      var input = document.createElement('input');
      input.setAttribute('disabled', 'disabled');
      input.setAttribute('type', 'checkbox');
      input.setAttribute('class', 'filled-in');
      input.setAttribute('checked', 'checked');
      input.setAttribute('id', 'show-checkbox-' + row);

      var span = document.createElement('span');
      span.setAttribute('for', 'show-checkbox-' + row);

      label.append(input);
      label.append(span);

      return applyStyle(label, columnDef.style_class, columnDef.style || 'text-align:center');
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
    },

    // Support growth values
    PercentageFormatter: function(row, cell, value, columnDef, dataContext) {
      if (columnDef.precision == undefined) {
        var precision = 0;
      } else {
        var precision = columnDef.precision;
      }

      if (precision == 0) {
        value = (value === null) ? '' : (parseInt(value) + '%');
      } else {
        value = (value === null) ? '' : (parseFloat(value).toFixed(precision) + '%');
      }

      return applyStyle(value, columnDef.style_class, columnDef.style || '');
    },

    // Depend on date.format.js
    DateFormatter: function(row, cell, value, columnDef, dataContext) {
      value = (value === null) ? '' : (new Date(value).format('isoDate')); // "YYYY-MM-DD"

      return applyStyle(value, columnDef.style_class, columnDef.style || '');
    }
  };

  $.extend(window, SlickFormatter);

})(jQuery);
