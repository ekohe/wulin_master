(function($) {

    function ColumnPicker(grid, options) {

        var $menu;
        var uid;

        var defaults = {
            fadeSpeed: 250,
            showCloseButton: true,
            showAutoResize: true,
            showSyncResize: true
        };

        function init() {
            grid.onHeaderContextMenu = displayContextMenu;
            uid = grid.getUID();

            options = $.extend({}, defaults, options);

            $menu = $("<div class='slick-columnpicker' style='display:none;position:absolute;z-index:20;' />").appendTo(document.body);

            $menu.bind("mouseleave", function(e) { $(this).fadeOut(options.fadeSpeed) });
            $menu.bind("click", updateColumn);
        }

        function displayContextMenu(e) {
            e.preventDefault();
            $menu.empty();

            var visibleColumns = grid.getColumns();
            var columns = grid.getAllColumns();
            var $li, $input;

            if (options.showCloseButton) {
                $('<div class="close_columnpicker"></div>').appendTo($menu).click(function() {
                    $menu.fadeOut(options.fadeSpeed);
                });
            }

            for (var i=0; i<columns.length; i++) {
                $li = $("<div />").appendTo($menu);

                $input = $("<input type='checkbox' />")
                    .attr("id", uid + "_columnpicker_" + i)
                    .data("id", columns[i].id)
                    .appendTo($li);

                if (grid.getColumnIndex(columns[i].id) != null || columns[i].alwaysDisplay) {
                    $input.attr("checked","checked");
                }

                $("<label for='" + uid + "_columnpicker_" + i + "' />")
                    .text(columns[i].name)
                    .appendTo($li);

                if (columns[i].alwaysDisplay) {
                    $li.hide();
                }
            }

            if (options.showAutoResize || options.showSyncResize) {
                $("<hr/>").appendTo($menu);
            }

            if (options.showAutoResize) {
                $li = $("<div />").appendTo($menu);
                $input = $("<input type='checkbox' id='" + uid + "_autoresize' />").appendTo($li);
                $("<label for='" + uid + "_autoresize'>Force Fit Columns</label>").appendTo($li);
                if (grid.getOptions().forceFitColumns) {
                    $input.attr("checked", "checked");
                }
            }

            if (options.showSyncResize) {
                $li = $("<div />").appendTo($menu);
                $input = $("<input type='checkbox' id='" + uid + "_syncresize' />").appendTo($li);
                $("<label for='" + uid + "_syncresize'>Synchronous Resizing</label>").appendTo($li);
                if (grid.getOptions().syncColumnCellResize) {
                    $input.attr("checked", "checked");
                }
            }

            // Toggle active class
            $('div', $menu).each(function() {
                if ($('input:checked', this).length) {
                    $('label', this).addClass('active');
                }
                $('input', this).click(function() {
                    $(this).next('label').toggleClass('active');
                });
            });

            var leftOffset = ((e.pageX + $menu.outerWidth() + 20) > $(window).width()) ? (e.pageX + $menu.outerWidth() + 20 - $(window).width()) : 15;
            $menu
                .css("top", e.pageY - 15)
                .css("left", e.pageX - leftOffset)
                .fadeIn(options.fadeSpeed);
        }

        function useColumnPreset(preset) {
            var visibleColumns = [];
            var allColumns = grid.getAllColumns();
            for (var i = 0; i < allColumns.length; i++) {
                var c = allColumns[i];
                // columns with special 'all' preset are always displayed
                if ($.inArray(preset, c.presets) !== -1 || $.inArray('all', c.presets) !== -1 || c.alwaysDisplay) {
                    allColumns[i].visible = true;
                    visibleColumns.push(allColumns[i]);
                }
                else {
                    allColumns[i].visible = false;
                }
            }
            grid.setAllColumns(allColumns);
            grid.setColumns(visibleColumns);
        }

        function updateColumn(e) {
            if (options.showAutoResize && e.target.id == (uid + '_autoresize')) {
                if (e.target.checked) {
                    grid.setOptions({forceFitColumns: true});
                    grid.autosizeColumns();
                }
                else {
                    grid.setOptions({forceFitColumns: false});
                }
                grid.setupColumnResize();
                return;
            }

            if (options.showSyncResize && e.target.id == (uid + '_syncresize')) {
                if (e.target.checked) {
                    grid.setOptions({syncColumnCellResize: true});
                }
                else {
                    grid.setOptions({syncColumnCellResize: false});
                }
                return;
            }

            if ($(e.target).is(":checkbox")) {

                $('div.' + uid).prevAll('div.slickgrid-controls:first').find('a.active').removeClass('active');

                if (!$menu.find(":checkbox:checked").length) {
                    $(e.target).attr("checked","checked");
                    return;
                }

                var visibleColumns = [];
                var allColumns = grid.getAllColumns();
                $menu.find(":checkbox[id*=columnpicker]").each(function(i,e) {
                    if ($(this).is(":checked")) {
                        allColumns[i].visible = true;
                        visibleColumns.push(allColumns[i]);
                    } else {
                        allColumns[i].visible = false;
                    }
                });
                grid.setAllColumns(allColumns);
                grid.setColumns(visibleColumns);
                setTimeout(grid.resizeGrid, 200);
            }
        }

        init();

        return {
            // Methods
            "displayContextMenu":       displayContextMenu,
            "useColumnPreset":          useColumnPreset
        };
    }

    // Slick.Controls.ColumnPicker
    $.extend(true, window, { Slick: { Controls: { ColumnPicker: ColumnPicker }}});

})(jQuery);
