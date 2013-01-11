/* THESE FORMATTERS ARE JUST SAMPLES! */
(function($) {
    var SlickFormatter = {

        RawFormatter: function(row, cell, value, columnDef, dataContext) {
            return (value == null) ? "" : value;
        },
  
        TooltipFormatter: function(row, cell, value, columnDef, dataContext) {
            return "<div title='" + columnDef.tooltips[value] + "'>" + "<span style='text-align:center;display:block'>" + value + "</span></div>"
        },

        SelectorCellFormatter : function(row, cell, value, columnDef, dataContext) {
            return (!dataContext ? "" : row);
        },

        PercentCompleteCellFormatter : function(row, cell, value, columnDef, dataContext) {
            if (value == null || value === "")
                return "-";
            else if (value < 50)
                return "<span style='color:red;font-weight:bold;'>" + value + "%</span>";
            else
                return "<span style='color:green'>" + value + "%</span>";
        },

        GraphicalPercentCompleteCellFormatter : function(row, cell, value, columnDef, dataContext) {
            if (value == null || value === "")
                return "";

            var color;

            if (value < 30)
                color = "red";
            else if (value < 70)
                color = "silver";
            else
                color = "green";

            return "<span class='percent-complete-bar' style='background:" + color + ";width:" + value + "%'></span>";
        },

        YesNoCellFormatter : function(row, cell, value, columnDef, dataContext) {
            return value ? "Yes" : "No";
        },

        BoolCellFormatter : function(row, cell, value, columnDef, dataContext) {
            // return value ? "<img src='/assets/tick.png'>" : "";
            return value == null ? "" : (value ? 'Yes' : 'No');
        },

        MoneyFormatter: function(row, cell, value, columnDef, dataContext) {
            // TODO: make the unit configurable
            var currency = columnDef.currency || "$";
            var text = (value == null || value == undefined || value == '') ? '' : parseFloat(value).toMoney(2, '.', ',') + ' ' +currency;
            return "<span style='text-align:right;display:block'>" + text + "</span>";
        },

        RightFormatter: function(row, cell, value, columnDef, dataContext) {
            return value == null ? "" : "<span style='text-align:right;display:block'>" + value + "</span>";
        },

        CenterFormatter: function(row, cell, value, columnDef, dataContext) {
            return value == null ? "" : "<span style='text-align:center;display:block'>" + value + "</span>";
        },

        TaskNameFormatter : function(row, cell, value, columnDef, dataContext) {
            // todo:  html encode
            var spacer = "<span style='display:inline-block;height:1px;width:" + (2 + 15 * dataContext["indent"]) + "px'></span>";
            return spacer + " <img src='../images/expand.gif'>&nbsp;" + value;
        },

        ResourcesFormatter : function(row, cell, value, columnDef, dataContext) {
            var resources = dataContext["resources"];

            if (!resources || resources.length == 0)
                return "";

            if (columnDef.width < 50)
                return (resources.length > 1 ? "<center><img src='../images/user_identity_plus.gif' " : "<center><img src='../images/user_identity.gif' ") +
                        " title='" + resources.join(", ") + "'></center>";
            else
                return resources.join(", ");
        },

        StarFormatter : function(row, cell, value, columnDef, dataContext) {
            return (value) ? "<img src='../images/bullet_star.png' align='absmiddle'>" : "";
        },
        
        // Date cell formatter to handle "yy-mm-dd" format (for StandardDateCellEditor)
        StandardDateCellFormatter: function(row, cell, value, columnDef, dataContext) {
            if (value == null || value === "") {
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
        SimpleDateFormatter: function(row, cell, value, columnDef, dataContext) {
            if (value == null || value === "") {
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
            if (value == null || value === "") {
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
        
        BelongsToFormatter : function(row, cell, value, columnDef, dataContext) {
            value = value[columnDef.optionTextAttribute];
            if(!columnDef.inner_formatter) return value;

            // if has inner_formatter
            if (columnDef.inner_formatter == 'boolean') {
                return BoolCellFormatter(row, cell, eval(value), columnDef, dataContext);
            } else if(typeof(window[columnDef.inner_formatter]) == 'function') {
                return window[columnDef.inner_formatter](row, cell, value, columnDef, dataContext);
            } else {
                return value;
            }
        },

        HasManyFormatter : function(row, cell, value, columnDef, dataContext) {
            return $.map(value, function(val,i) { return val[columnDef.optionTextAttribute]; }).join(", ");
        },
        
        HasOneFormatter : function(row, cell, value, columnDef, dataContext) {
            return value[columnDef.optionTextAttribute];
        },
    
    };

  $.extend(window, SlickFormatter);

})(jQuery);
