/* THESE FORMATTERS ARE JUST SAMPLES! */
(function($) {
    var SlickFormatter = {

        RawFormatter: function(row, cell, value, columnDef, dataContext) {
            return (value === null) ? "" : value;
        },

        TooltipFormatter: function(row, cell, value, columnDef, dataContext) {
            return "<div title='" + columnDef.tooltips[value] + "'>" + "<span style='text-align:center;display:block'>" + value + "</span></div>";
        },

        SelectorCellFormatter: function(row, cell, value, columnDef, dataContext) {
            return (!dataContext ? "" : row);
        },

        YesNoCellFormatter: function(row, cell, value, columnDef, dataContext) {
            return value ? "Yes" : "No";
        },

        GraphicBoolCellFormatter: function(row, cell, value, columnDef, dataContext) {
            return value ? "<img src='/assets/tick.png'>" : "";
            // return value === null ? "" : (value ? "<img src='/assets/tick.png'>" : "<img src='/assets/cross.png'>");
        },

        TextBoolCellFormatter: function(row, cell, value, columnDef, dataContext) {
            return value === null ? "" : (value ? 'Yes' : 'No');
        },

        MoneyFormatter: function(row, cell, value, columnDef, dataContext) {
            // TODO: make the unit configurable
            var currency = columnDef.currency || "$";
            var text = (value === null || value === undefined || value === '') ? '' : parseFloat(value).toMoney(2, '.', ',') + ' ' + currency;
            return "<span style='text-align:right;display:block'>" + text + "</span>";
        },

        RightFormatter: function(row, cell, value, columnDef, dataContext) {
            return value === null ? "" : "<span style='text-align:right;display:block'>" + value + "</span>";
        },

        CenterFormatter: function(row, cell, value, columnDef, dataContext) {
            return value === null ? "" : "<span style='text-align:center;display:block'>" + value + "</span>";
        },

        StarFormatter: function(row, cell, value, columnDef, dataContext) {
            return (value) ? "<img src='../images/bullet_star.png' align='absmiddle'>" : "";
        },

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

        BelongsToFormatter: function(row, cell, value, columnDef, dataContext) {
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
        },

        HasManyFormatter: function(row, cell, value, columnDef, dataContext) {
            return BelongsToFormatter(row, cell, value, columnDef, dataContext);
        },

        HasOneFormatter: function(row, cell, value, columnDef, dataContext) {
            return BelongsToFormatter(row, cell, value, columnDef, dataContext);
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
        },

        ZeroFormatter: function(row, cell, value, columnDef, dataContext) {
            return value === 0 ? "" : "<span style='text-align:right;display:block'>" + value + "</span>";
        },

        LinkFormatter: function(row, cell, value, columnDef, dataContext) {
            var urlReg = /https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)/
            if (value) {
                if (urlReg.test(value)) {
                    return '<a target="_blank" href="' + value + '">' + value + '</a>';
                } else {
                    return value;
                }
            } else {
                return null;
            }
        }
    };

    $.extend(window, SlickFormatter);

})(jQuery);
