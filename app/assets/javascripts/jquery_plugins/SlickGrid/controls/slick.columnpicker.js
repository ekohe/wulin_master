(function ($) {
  function SlickColumnPicker(columns, grid, user_id, options) {
    var $menu;
    var columnCheckboxes;
    var _self = this;   // Ekohe Add

    var defaults = {
      fadeSpeed:250
    };

    // Ekohe Edit: for MD implementation
    //   1. Add menu container div
    //   2. Use MaterializedCSS's card-panel class
    //   3. Use wulin-columnpicker class for customization

    function init() {
      grid.onHeaderContextMenu.subscribe(handleHeaderContextMenu);
      grid.onColumnsReordered.subscribe(updateColumnOrder);
      options = $.extend({}, defaults, options);

      // Ekohe Edit
      // $menu = $("<span class='slick-columnpicker' style='display:none;position:absolute;z-index:20;overflow-y:scroll;' />").appendTo(document.body);
      $menu = $("<div class='card-panel wulin-columnpicker' style='display:none;position:absolute;z-index:20;' />")
        .attr('id', grid.name + '-columnpicker')
        .appendTo(document.body);

      $menu.on("mouseleave", function (e) {
        $(this).fadeOut(options.fadeSpeed)
      });
      $menu.on("click", updateColumn);

      // Ekohe Add: bind the column pick event
      $menu.bind("click", handleColumnPick);
      bindGrid();
    }

    // Ekohe Add: Assign the picker itself to grid
    function bindGrid() {
      grid.picker = _self;
    }

    // Ekohe Add: Bind the column pick event
    function handleColumnPick(e, args) {
      _self.onColumnsPick.notify({});
    }

    function destroy() {
      grid.onHeaderContextMenu.unsubscribe(handleHeaderContextMenu);
      grid.onColumnsReordered.unsubscribe(updateColumnOrder);
      $menu.remove();
    }

    // Ekohe Edit:
    //  1. Add column-container div for MD implementation
    //  2. Add "Reset to defaults" feature
    //  3. Remove "Force Fit Columns" & "Synchronous Resizing" features

    function handleHeaderContextMenu(e, args) {
      e.preventDefault();
      $menu.empty();
      updateColumnOrder();
      columnCheckboxes = [];

      var $li, $input, $allNoneInput;

      // Ekohe Edit: Add column-container div for MD implementation
      var $columnContainer = $("<div class='column-container' />").appendTo($menu);

      // Append columns checkbox
      for (var i = 0; i < columns.length; i++) {
        $li = $("<li />").appendTo($columnContainer);
        // Ekohe Edit: MD implementation
        // $input = $("<input type='checkbox' />").data("column-id", columns[i].id);
        $input = $("<input type='checkbox' />")
                  .attr({id: "columnpicker_" + i, name: columns[i].field})
                  .appendTo($li);
        columnCheckboxes.push($input);

        if (grid.getColumnIndex(columns[i].id) != null) {
          $input.attr("checked", "checked")
                // Ekohe Add: MD implementation
                .addClass("filled-in");
        }

        // Ekohe Edit: MD implementation
        $("<label />")
          .attr("for", "columnpicker_" + i)
          .text(columns[i].name)
          // .prepend($input);
          .appendTo($li);
      }

      // Ekohe Add
      // Addpend "Reset to defaults" checkbox
      $("<hr/>").appendTo($menu);
      $a = $("<a id='reset_to_default' href='#' />").appendTo($menu);
      $icon = $("<i class='material-icons'>replay</i>").appendTo($a);
      $("<span />").html("RESET TO DEFAULTS").appendTo($a);
      $a.on("click", function() {
        $('#confirm-modal').modal('open');
        $('#confirmed-btn').on('click', function() {
          $.post('/wulin_master/grid_states_manages/reset_default',
                 { _method: 'PUT',
                   grid_name: grid.name,
                   user_id: user_id
                 },
                 function(data) {
                   if (data == 'ok') {
                     load_page(History.getState().url);
                   } else {
                     displayErrorMessage(data);
                   }
                 });
          $('#confirm-modal').modal('close');
        })
      });

      // Ekohe Delete
      // Addpend "Force Fit Columns" checkbox
      // $("<hr/>").appendTo($menu);
      // $li = $("<li />").appendTo($menu);
      // $input = $("<input type='checkbox' />").data("option", "autoresize");
      // $("<label />")
      //   .text("Force fit columns")
      //   .prepend($input)
      //   .appendTo($li);
      // if (grid.getOptions().forceFitColumns) {
      //   $input.attr("checked", "checked");
      // }

      // Ekohe Delete
      // Addpend "Synchronous Resizing" checkbox
      // $li = $("<li />").appendTo($menu);
      // $input = $("<input type='checkbox' />").data("option", "syncresize");
      // $("<label />")
      //   .text("Synchronous resize")
      //   .prepend($input)
      //   .appendTo($li);
      // if (grid.getOptions().syncColumnCellResize) {
      //   $input.attr("checked", "checked");
      // }

      // Ekohe Edit: MD implementation
      $menu
        // .css("top", e.pageY - 10)
        .css("top", e.pageY + 10)
        .css("left", e.pageX - 10)
        // .css("max-height", $(window).height() - e.pageY -10)
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

    // Ekohe Edit:
    //  1. Remove "Force Fit Columns" & "Synchronous Resizing" features

    function updateColumn(e) {
      // Ekohe Delete
      // "Force Fit Columns" checkbox hanlder
      // if ($(e.target).data("option") == "autoresize") {
      //   if (e.target.checked) {
      //     grid.setOptions({forceFitColumns:true});
      //     grid.autosizeColumns();
      //   } else {
      //     grid.setOptions({forceFitColumns:false});
      //   }
      //   return;
      // }

      // Ekohe Delete
      // "Synchronous Resizing" checkbox hanlder
      // if ($(e.target).data("option") == "syncresize") {
      //   if (e.target.checked) {
      //     grid.setOptions({syncColumnCellResize:true});
      //   } else {
      //     grid.setOptions({syncColumnCellResize:false});
      //   }
      //   return;
      // }

      // Ekohe Edit
      //   Use specifc class to identify columnpicker since e.target
      //   is recognized as label (should be input) here.
      //   TODO: Use e.target instead of using columnpicker element

      // // Column checkbox handler
      // if ($(e.target).is(":checkbox")) {
      //   var visibleColumns = [];
      //   $.each(columnCheckboxes, function (i, e) {
      //     if ($(this).is(":checked")) {
      //       visibleColumns.push(columns[i]);
      //     }
      //   });
      //
      //   if (!visibleColumns.length) {
      //     // Ekohe Edit
      //     // $(e.target).attr("checked", "checked");
      //     $(e.target).attr("checked", "checked")
      //                .addClass("filled-in");
      //     return;
      //   }
      //
      //   grid.setColumns(visibleColumns);
      // }

      var visibleColumns = [];
      $.each($('#' + grid.name + '-columnpicker li input'), function(i, e) {
        if ($(this).is(":checked")) {
          visibleColumns.push(columns[i]);
          $(this).addClass("filled-in");
        }
      });
      grid.setColumns(visibleColumns);

      // Ekohe Add: Reset filters
      grid.filterPanel.setupEventHander();
      grid.filterPanel.generateFilters();
    }

    function getAllColumns() {
      return columns;
    }

    ///////////////////////////////////////////////////////////
    // Ekohe Add: New getter/setters

    function getMenu() {
      return $menu;
    }

    function getColumnCheckboxes() {
      return columnCheckboxes;
    }

    init();

    // Ekohe Modify: Use extend instead of return to set APIs to this
    $.extend(this, {
    // return {
      "onColumnsPick": new Slick.Event(),

      "destroy": destroy,
      "getAllColumns": getAllColumns
    });

  }

  // Slick.Controls.ColumnPicker
  $.extend(true, window, { Slick:{ Controls:{ ColumnPicker:SlickColumnPicker }}});
})(jQuery);
