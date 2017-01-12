(function ($) {
  function SlickColumnPicker(columns, grid, options) {
    var $menu;
    var columnCheckboxes;
    var _self = this;   // Ekohe Add

    var defaults = {
      fadeSpeed:250
    };

    function init() {
      grid.onHeaderContextMenu.subscribe(handleHeaderContextMenu);
      grid.onColumnsReordered.subscribe(updateColumnOrder);
      options = $.extend({}, defaults, options);

      $menu = $("<span class='slick-columnpicker' style='display:none;position:absolute;z-index:20;overflow-y:scroll;' />").appendTo(document.body);

      $menu.on("mouseleave", function (e) {
        $(this).fadeOut(options.fadeSpeed)
      });
      $menu.on("click", updateColumn);

      // Ekohe Add: Bind the column pick event
      $menu.on("click", handleColumnPick);
      bindGrid();
    }

    // Ekohe Add: Assign the picker itself to grid
    function bindGrid() {
      grid.picker = _self;
    }

    // Ekohe Add: Notify onColumnsPick event
    function handleColumnPick(e, args) {
      _self.onColumnsPick.notify({});
    }

    function destroy() {
      grid.onHeaderContextMenu.unsubscribe(handleHeaderContextMenu);
      grid.onColumnsReordered.unsubscribe(updateColumnOrder);
      $menu.remove();
    }

    // Ekohe Modify:
    //   1. Add "All/None" checkbox
    //   2. Use attr instead of data for columns checkbox
    //   3. Add process for "All/None" checkbox in columns checkbox
    function handleHeaderContextMenu(e, args) {
      e.preventDefault();
      $menu.empty();
      updateColumnOrder();
      columnCheckboxes = [];

      var $li, $input, $allNoneInput;

      // Ekohe Add: Append "All/None" checkbox
      $li = $("<li />").appendTo($menu);
      $allNoneInput = $("<input type='checkbox' id='all_none' checked='checked' />").appendTo($li);
      $("<label for='all_none'>All/None</label>").appendTo($li);
      $("<hr/>").appendTo($menu);

      // Append columns checkbox
      for (var i = 0; i < columns.length; i++) {
        $li = $("<li />").appendTo($menu);
        // Ekohe Modify: Use attr instead of data for columns checkbox
        $input = $("<input type='checkbox' />").attr({id: "columnpicker_" + i, name: columns[i].field})
        // $input = $("<input type='checkbox' />").data("column-id", columns[i].id);
        columnCheckboxes.push($input);

        if (grid.getColumnIndex(columns[i].id) != null) {
          $input.attr("checked", "checked");
        // Ekohe Add: Uncheck "All/None" when unchecked columns exist
        } else {
          $allNoneInput.removeAttr("checked");
        }

        $("<label />")
          .html(columns[i].name)
          .prepend($input)
          .appendTo($li);
      }

      // Addpend "Force Fit Columns" checkbox
      $("<hr/>").appendTo($menu);
      $li = $("<li />").appendTo($menu);
      $input = $("<input type='checkbox' />").data("option", "autoresize");
      $("<label />")
          .text("Force fit columns")
          .prepend($input)
          .appendTo($li);
      if (grid.getOptions().forceFitColumns) {
        $input.attr("checked", "checked");
      }

      // Addpend "Synchronous Resizing" checkbox
      $li = $("<li />").appendTo($menu);
      $input = $("<input type='checkbox' />").data("option", "syncresize");
      $("<label />")
        .text("Synchronous resize")
        .prepend($input)
        .appendTo($li);
      if (grid.getOptions().syncColumnCellResize) {
        $input.attr("checked", "checked");
      }

      $menu
        .css("top", e.pageY - 10)
        .css("left", e.pageX - 10)
        .css("max-height", $(window).height() - e.pageY -10)
        .fadeIn(options.fadeSpeed);
    }

    function updateColumnOrder() {
      // Because columns can be reordered, we have to update the `columns`
      // to reflect the new order, however we can't just take `grid.getColumns()`,
      // as it does not include columns currently hidden by the picker.
      // We create a new `columns` structure by leaving currently-hidden
      // columns in their original ordinal position and interleaving the results
      // of the current column sort.
      var current = grid.getColumns().slice(0);
      var ordered = new Array(columns.length);
      for (var i = 0; i < ordered.length; i++) {
        if ( grid.getColumnIndex(columns[i].id) === undefined ) {
          // If the column doesn't return a value from getColumnIndex,
          // it is hidden. Leave it in this position.
          ordered[i] = columns[i];
        } else {
          // Otherwise, grab the next visible column.
          ordered[i] = current.shift();
        }
      }
      columns = ordered;
    }

    // Ekohe Modify:
    //   1. "All/None" checkbox hanlder
    function updateColumn(e) {
      // "Force Fit Columns" checkbox hanlder
      if ($(e.target).data("option") == "autoresize") {
        if (e.target.checked) {
          grid.setOptions({forceFitColumns:true});
          grid.autosizeColumns();
        } else {
          grid.setOptions({forceFitColumns:false});
        }
        return;
      }

      // "Synchronous Resizing" checkbox hanlder
      if ($(e.target).data("option") == "syncresize") {
        if (e.target.checked) {
          grid.setOptions({syncColumnCellResize:true});
        } else {
          grid.setOptions({syncColumnCellResize:false});
        }
        return;
      }

      // Ekohe Add: "All/None" checkbox hanlder
      if (e.target.id == 'all_none') {
        if (e.target.checked) {
          $menu.find(":checkbox[id^=columnpicker]").attr('checked', 'checked');
          $menu.find(":checkbox").attr('checked', 'checked');
          grid.setColumns(columns);
        } else {
          $menu.find(":checkbox[id^=columnpicker]").not("[name='id']").removeAttr('checked');
          idColumns = $.grep(grid.getColumns(), function(n, i){
            return (n.field == 'id');
          });
          grid.setColumns(idColumns);
        }
        return;
      }

      // Column checkbox handler
      if ($(e.target).is(":checkbox")) {
        var visibleColumns = [];
        $.each(columnCheckboxes, function (i, e) {
          if ($(this).is(":checked")) {
            visibleColumns.push(columns[i]);
          }
        });

        if (!visibleColumns.length) {
          $(e.target).attr("checked", "checked");
          return;
        }

        grid.setColumns(visibleColumns);
      }
    }

    function getAllColumns() {
      return columns;
    }

    // Ekohe fork
    // define the columns pick event
    $.extend(this, {
      // Events
      "onColumnsPick":    new Slick.Event()
    });

    init();

    return {
      "getAllColumns": getAllColumns,
      "destroy": destroy
    };
  }

  // Slick.Controls.ColumnPicker
  $.extend(true, window, { Slick:{ Controls:{ ColumnPicker:SlickColumnPicker }}});
})(jQuery);
