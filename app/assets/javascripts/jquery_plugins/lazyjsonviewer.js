(function () {
    $.fn.jsonViewer = function (obj) {
        createViewer(obj, this);
    }

    function createViewer(obj, target) {
        var el = $("<div>").addClass("lazy-json-viewer");
        writeValue(obj, el);
        el.appendTo(target);
    }

    function writeValue(val, target) {
        var el = $("<div>").appendTo(target);
        switch (typeof val) {
            case "object":
                if (val === null) {
                    el.addClass("null-value").text("null");
                }
                else {
                    var length = Object.keys(val).length;
                    el.addClass(Array.isArray(val) ? "array-value" : "object-value");
                    var labelEl = $("<div>").addClass("value-summary").text(length).appendTo(el);
                    var content = $("<div>").addClass("content").appendTo(el);
                    if (length) {
                        var expander = addExpander(val, el);
                        if (expander) {
                            expander.one("click", function () {
                                writeProperties(val, content);
                            });
                        }
                        else {
                            writeProperties(val, content);
                        }
                    }
                }
                break;
            case "string":
                if (/\n/.test(val)) {
                    el.addClass("multiline");
                    addExpander(val, el);
                }
                if (/"/.test(val)) {
                    if (/`/.test(val)) {
                        val = val.replace(/"/g, '\\"');

                    }
                    else {
                        el.addClass("containsQuote");
                    }
                }
            default:
                el.addClass((typeof val) + "-value").text(val);
                break;
        }
        return el;
    }

    function writeProperties(val, target) {
        Object.keys(val).forEach(function (key) {
            var propEl = $("<div>").addClass("property").attr("data-property-name", key).attr("data-property-val", val[key]).appendTo(target)
            $("<div>").addClass("property-name").text(key + ":").appendTo(propEl);
            writeValue(val[key], propEl);
        });
    }

    function addExpander(val, el) {
        if (!el.parent().is(".lazy-json-viewer")) {
            var expander = el.parent().addClass("collapsed").children(".property-name").addClass("json-expander");
            expander.click(function (e) {
                $(this).parent().toggleClass("collapsed");
            });
            return expander;
        }
    }
})();
