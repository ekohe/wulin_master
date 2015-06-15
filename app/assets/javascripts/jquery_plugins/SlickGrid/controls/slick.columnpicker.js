(function($) {
  function SlickColumnPicker(columns,grid,options)
  {
    var $menu;
    var columnCheckboxes;
    var _self = this;   // Ekohe fork

    var defaults = {
      fadeSpeed: 250
    };

    function init() {
      grid.onHeaderContextMenu.subscribe(handleHeaderContextMenu);
      options = $.extend({}, defaults, options);

      $menu = $("<span class='slick-columnpicker' style='display:none;position:absolute;z-index:10250;' />").appendTo(document.body);

      $menu.bind("mouseleave", function(e) { $(this).fadeOut(options.fadeSpeed) });
      $menu.bind("click", updateColumn);

      // Ekohe fork
      // bind the column pick event
      $menu.bind("click", handleColumnPick);
      bindGrid();
      // ------------------------------------------------
    }

    // Ekohe fork
    // assign the picker itself to grid
    function bindGrid() {
      grid.picker = _self;
    }
    // --------------------------------------------------

    function handleHeaderContextMenu(e, args)
    {
      e.preventDefault();
      $menu.empty();
      updateColumnOrder();
      columnCheckboxes = [];

      var $li, $input, $allNoneInput;

      // Append "All/None" checkbox
      $li = $("<li />").appendTo($menu);
      $allNoneInput = $("<input type='checkbox' id='all_none' checked='checked' />").appendTo($li);
      $("<label for='all_none'>All/None</label>").appendTo($li);
      $("<hr/>").appendTo($menu);

      // Append columns checkbox
      for (var i=0; i<columns.length; i++) {
        $li = $("<li />").appendTo($menu);

        $input = $("<input type='checkbox' />").data("column-id", columns[i].id);
        columnCheckboxes.push($input);

        if (grid.getColumnIndex(columns[i].id) != null) {
          $input.attr("checked","checked");
        } else {
          $allNoneInput.removeAttr("checked");
        }

        $("<label />")
          .text(columns[i].name)
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
      if (grid.getOptions().forceFitColumns)
        $input.attr("checked", "checked");

      // Addpend "Synchronous Resizing" checkbox
      $li = $("<li />").appendTo($menu);
      $input = $("<input type='checkbox' />").data("option", "syncresize");
      $("<label />")
          .text("Synchronous resize")
          .prepend($input)
          .appendTo($li);
      if (grid.getOptions().syncColumnCellResize)
        $input.attr("checked", "checked");

      $menu
        .css("top", e.pageY - 10)
        .css("left", e.pageX - 10)
        .fadeIn(options.fadeSpeed);
    }

    function handleColumnPick(e, args) {
      _self.onColumnsPick.notify({});
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

    function updateColumn(e) {
      var newWidths = {};
      var idColumns;

      $.each(grid.getColumns(), function(i, column){
        newWidths[column.id] = column.width;
      });

      $.each(columns, function(i, column){
        if (newWidths[column.id]) {
          columns[i].width = newWidths[column.id];
        }
      });

      // "Force Fit Columns" checkbox hanlder
      if ($(e.target).data("option") == "autoresize") {
        if (e.target.checked) {
          grid.setOptions({forceFitColumns: true});
          grid.autosizeColumns();
        } else {
          grid.setOptions({forceFitColumns: false});
        }
        return;
      }

      // "Synchronous Resizing" checkbox hanlder
      if ($(e.target).data("option") == "syncresize") {
        if (e.target.checked) {
          grid.setOptions({syncColumnCellResize: true});
        } else {
          grid.setOptions({syncColumnCellResize: false});
        }
        return;
      }

      // "All/None" checkbox hanlder
      if (e.target.id == 'all_none') {
        if (e.target.checked) {
          $menu.find(":checkbox[id^=columnpicker]").attr('checked', 'checked');
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

    // Ekohe fork
    // define the columns pick event
    $.extend(this, {
      // Events
      "onColumnsPick":    new Slick.Event()
    });
    // ------------------------------------------

    function getAllColumns() {
      return columns;
    }

    init();

    return {
      "getAllColumns": getAllColumns
    };
  }

  // Slick.Controls.ColumnPicker
  $.extend(true, window, { Slick: { Controls: { ColumnPicker: SlickColumnPicker }}});
})(jQuery);
