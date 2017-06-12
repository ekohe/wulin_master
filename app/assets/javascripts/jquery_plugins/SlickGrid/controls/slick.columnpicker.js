(function ($) {
  function SlickColumnPicker(columns, grid, options) {
    var $menu;
    var columnCheckboxes;

    var defaults = {
      fadeSpeed:250
    };

    function init() {
      grid.onHeaderContextMenu.subscribe(handleHeaderContextMenu);
      grid.onColumnsReordered.subscribe(updateColumnOrder);
      options = $.extend({}, defaults, options);

      // Ekohe Edit
      // $menu = $("<span class='slick-columnpicker' style='display:none;position:absolute;z-index:20;overflow-y:scroll;' />").appendTo(document.body);
      var $menuContainer = $("<div class='columnpicker-container' />").appendTo(document.body);
      $menu = $("<div class='card-panel wulin-columnpicker' style='display:none;position:absolute;z-index:20;' />").appendTo($menuContainer);

      $menu.on("mouseleave", function (e) {
        $(this).fadeOut(options.fadeSpeed)
      });
      $menu.on("click", updateColumn);
    }

    function destroy() {
      grid.onHeaderContextMenu.unsubscribe(handleHeaderContextMenu);
      grid.onColumnsReordered.unsubscribe(updateColumnOrder);
      $menu.remove();
    }

    function handleHeaderContextMenu(e, args) {
      e.preventDefault();
      $menu.empty();
      updateColumnOrder();
      columnCheckboxes = [];

      var $li, $input, $allNoneInput;

      var $columnContainer = $("<div class='column-container' />").appendTo($menu);

      // Append columns checkbox
      for (var i = 0; i < columns.length; i++) {
        $li = $("<li />").appendTo($columnContainer);
        // Ekohe Edit
        // $input = $("<input type='checkbox' />").data("column-id", columns[i].id);
        $input = $("<input type='checkbox' />")
                  .attr({id: "columnpicker_" + i, name: columns[i].field})
                  // .data("column-id", columns[i].id)
                  .appendTo($li);
        columnCheckboxes.push($input);

        if (grid.getColumnIndex(columns[i].id) != null) {
          $input.attr("checked", "checked")
                .addClass("filled-in");
        }

        $("<label />")
          .attr("for", "columnpicker_" + i)
          .text(columns[i].name)
          // .prepend($input);
          .appendTo($li);
      }

      // Ekohe Add
      // Addpend "Reset to defaults" checkbox
      $("<hr/>").appendTo($menu);
      $li = $("<li />").appendTo($menu);
      $a = $("<a id='reset_to_default' href='#' />").appendTo($li);
      $icon = $("<i class='material-icons'>replay</i>").appendTo($a);
      $("<span />").html("RESET TO DEFAULTS").appendTo($a);
      $a.on("click", function() {
        if (confirm('Are you sure that you want to reset the default view?')) {
          $.post('/wulin_master/grid_states_manages/reset_default', {_method: 'PUT', grid_name: '#{grid.name}', user_id: '#{current_user.id}'}, function(data) {
            if (data == 'ok') {
              load_page(History.getState().url);
            } else {
              displayErrorMessage(data);
            }
          });
        }
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

      // Ekohe Edit
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
      $.each($(".wulin-columnpicker li input"), function(i, e) {
        if ($(this).is(":checked")) {
          visibleColumns.push(columns[i]);
          $(this).addClass("filled-in");
        }
      });
      grid.setColumns(visibleColumns);
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

    // Ekohe Delete: Will be called in WulinMasterColumnPicker
    // init();

    // Ekohe Modify: Use extend instead of return to set APIs to this
    $.extend(this, {
    // return {
      "getMenu": getMenu,                                 // Ekohe Add
      "getColumnCheckboxes": getColumnCheckboxes,         // Ekohe Add
      "init": init,                                       // Ekohe Add
      "updateColumn": updateColumn,                       // Ekohe Add
      "handleHeaderContextMenu": handleHeaderContextMenu, // Ekohe Add
      // "destroy": destroy // Ekohe Delete (should use WulinMasterColumnPicker's API)
      "getAllColumns": getAllColumns
    });
  }

  // Slick.Controls.ColumnPicker
  $.extend(true, window, { Slick:{ Controls:{ ColumnPicker:SlickColumnPicker }}});
})(jQuery);
