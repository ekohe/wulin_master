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
      const { precision = 0, prefix = "", suffix = "", fallback = "" } = columnDef;

      const formatWithPrecision = (value, precision) => parseInt(precision) === 0
        ? parseInt(value).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
        : parseFloat(value).toFixed(precision).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");

      const text = (value => {
        const isEmpty = value === null || value === undefined || value === "";
        if (isEmpty) return fallback;
        return `${prefix}${formatWithPrecision(value, precision)}${suffix}`;
      })(value);

      return applyStyle(text, columnDef.style_class, columnDef.style || '');
    },

    URLFormatter: function(row, cell, value, columnDef, dataContext) {
      var element = document.createElement("span")
      element.setAttribute("style", "display: inline-block;color: #1068bf; text-decoration: underline;")
      element.innerText = value

      return applyStyle(element, columnDef.style_class, columnDef.style || '');
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
      var text = value === null ? '' : (value ? 'Yes' : 'No');

      if( Array.isArray(value) ) {
        text = value.filter(e => e != null).map( e => ( e ? 'Yes' : 'No' )).join(', ')
      }

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
      input.setAttribute('id', `show-checkbox-${row}-${cell}`);

      var span = document.createElement('span');
      span.setAttribute('for', `show-checkbox-${row}-${cell}`);

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
      const {percentageSign = "%"} = columnDef

      if (columnDef.precision == undefined) {
        var precision = 0;
      } else {
        var precision = columnDef.precision;
      }

      if (precision == 0) {
        value = (value === null) ? '' : (parseInt(value) + percentageSign);
      } else {
        value = (value === null) ? '' : (parseFloat(value).toFixed(precision) + percentageSign);
      }

      return applyStyle(value, columnDef.style_class, columnDef.style || '');
    },

    // stored in decimal, rendered in percentage, e.g. 0.12 -> 12%
    DecimalPercentageFormatter: function(row, cell, value, columnDef, dataContext) {
      let {precision, style_class, style, percentageSign = "%"} = columnDef;
      precision = precision || 0;

      if(Number(value) === 0) {
        value = ""
      } else {
        const parsedNum = Number(value) * 100

        if (precision === 0) {
          value = parseInt(parsedNum) + percentageSign
        } else {
          value = parseFloat(parsedNum).toFixed(precision) + percentageSign
        }
      }

      return applyStyle(value, style_class, style || '');
    },

    DeleteRedundantDecimals: function (
      row,
      cell,
      value,
      columnDef,
      dataContext
    ) {
      if (!value) { return '' }

      let precision = columnDef.precision || 0

      value = parseFloat(value).toFixed(precision).toString()

      let regexp = new RegExp(`(.0{${precision}}$)`)
      value = regexp.test(value) ? value.replace(RegExp.$1, '') : value
      return this.applyStyle(
        value,
        columnDef.style_class,
        columnDef.style || ''
      )
    },

    // Depend on date.format.js
    DateFormatter: function(row, cell, value, columnDef, dataContext) {
      value = (value === null) ? '' : (new Date(value).format('isoDate')); // "YYYY-MM-DD"

      return applyStyle(value, columnDef.style_class, columnDef.style || '');
    },

    NullOverrideFormatter: function(row, cell, value, columnDef) {
      if (value === null && columnDef.value_to_replace_null !== undefined) {
        value = columnDef.value_to_replace_null
      }

      return applyStyle(value, columnDef.style_class, columnDef.style || '');
    },

  };

  $.extend(window, SlickFormatter);

})(jQuery);
