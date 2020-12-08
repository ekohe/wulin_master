/***
 * A control to add a Column Picker (right+click on any column header to reveal the column picker)
 *
 * USAGE:
 *
 * Add the slick.columnpicker.(js|css) files and register it with the grid.
 *
 * Available options, by defining a columnPicker object:
 *
 *  var options = {
 *    enableCellNavigation: true,
 *    columnPicker: {
 *      columnTitle: "Columns",                 // default to empty string
 *
 *      // the last 2 checkboxes titles
 *      hideForceFitButton: false,              // show/hide checkbox near the end "Force Fit Columns" (default:false)
 *      hideSyncResizeButton: false,            // show/hide checkbox near the end "Synchronous Resize" (default:false)
 *      forceFitTitle: "Force fit columns",     // default to "Force fit columns"
 *      syncResizeTitle: "Synchronous resize",  // default to "Synchronous resize"
 *    }
 *  };
 *
 * @class Slick.Controls.ColumnPicker
 * @constructor
 */

 /*
  * Ekohe fork:
  *
  *   1. Material Design
  *   2. Add "Reset to defaults" feature
  *   3. Remove "Force Fit Columns" & "Synchronous Resizing" features
  */

'use strict';

(function ($) {
  // Ekohe Edit: Add user_id as param to get user based grid setting info
  // function SlickColumnPicker(columns, grid, options) {
  function SlickColumnPicker(columns, grid, user_id, options) {
    var _grid = grid;
    var $list;
    var $menu;
    var columnCheckboxes;
    var onColumnsChanged = new Slick.Event();

    var defaults = {
      fadeSpeed: 250,

      // the last 2 checkboxes titles
      hideForceFitButton: false,
      hideSyncResizeButton: false,
      forceFitTitle: "Force fit columns",
      syncResizeTitle: "Synchronous resize"
    };

    // Ekohe Add
    var _self = this;

    function init(grid) {
      // Ekohe Edit: Use customized handler
      // grid.onHeaderContextMenu.subscribe(handleHeaderContextMenu);
      grid.onHeaderContextMenu.subscribe(wulinHandleHeaderContextMenu);
      grid.onColumnsReordered.subscribe(updateColumnOrder);
      options = $.extend({}, defaults, options);

      // Ekohe Edit
      // $menu = $("<div class='slick-columnpicker' style='display:none' />").appendTo(document.body);
      // var $close = $("<button type='button' class='close' data-dismiss='slick-columnpicker' aria-label='Close'><span class='close' aria-hidden='true'>&times;</span></button>").appendTo($menu);
      $menu = $("<div class='card-panel wulin-columnpicker' style='display:none;position:absolute;z-index:20;' />")
        .attr('id', grid.name + '-columnpicker')
        .appendTo(document.body);

      // user could pass a title on top of the columns list
      if(options.columnPickerTitle || (options.columnPicker && options.columnPicker.columnTitle)) {
        var columnTitle = options.columnPickerTitle || options.columnPicker.columnTitle;
        var $title = $("<div class='title'/>").append(columnTitle);
        $title.appendTo($menu);
      }

      // Ekohe Edit: Use customized handler
      // $menu.on("click", updateColumn);
      $menu.on("click", wulinUpdateColumn);
      $list = $("<span class='slick-columnpicker-list' />");

      // Hide the menu on outside click.
      $(document.body).on("mousedown", handleBodyMouseDown);

      // destroy the picker if user leaves the page
      $(window).on("beforeunload", destroy);

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
      _grid.onHeaderContextMenu.unsubscribe(handleHeaderContextMenu);
      _grid.onColumnsReordered.unsubscribe(updateColumnOrder);
      $(document.body).off("mousedown", handleBodyMouseDown);
      $("div.slick-columnpicker").hide(options.fadeSpeed);
      $menu.remove();
    }

    function handleBodyMouseDown(e) {
      if (($menu && $menu[0] != e.target && !$.contains($menu[0], e.target)) || e.target.className == "close") {
        $menu.hide(options.fadeSpeed);
      }
    }

    function handleHeaderContextMenu(e, args) {
      e.preventDefault();
      $list.empty();
      updateColumnOrder();
      columnCheckboxes = [];

      var $li, $input;
      for (var i = 0; i < columns.length; i++) {
        $li = $("<li />").appendTo($list);
        $input = $("<input type='checkbox' />").data("column-id", columns[i].id);
        columnCheckboxes.push($input);

        if (_grid.getColumnIndex(columns[i].id) != null) {
          $input.attr("checked", "checked");
        }

        $("<span />")
            .html(columns[i].name)
            .prepend($input)
            .appendTo($li);

        $li.children().wrapAll($('<label />'));
      }

      if (options.columnPicker && (!options.columnPicker.hideForceFitButton || !options.columnPicker.hideSyncResizeButton)) {
        $("<hr/>").appendTo($list);
      }

      if (!(options.columnPicker && options.columnPicker.hideForceFitButton)) {
        var forceFitTitle = (options.columnPicker && options.columnPicker.forceFitTitle) || options.forceFitTitle;
        $li = $("<li />").appendTo($list);
        $input = $("<input type='checkbox' />").data("option", "autoresize");
        $("<span />")
            .text(forceFitTitle)
            .prepend($input)
            .appendTo($li);
        if (_grid.getOptions().forceFitColumns) {
          $input.attr("checked", "checked");
        }
        $li.children().wrapAll($('<label />'));
      }

      if (!(options.columnPicker && options.columnPicker.hideSyncResizeButton)) {
        var syncResizeTitle = (options.columnPicker && options.columnPicker.syncResizeTitle) || options.syncResizeTitle;
        $li = $("<li />").appendTo($list);
        $input = $("<input type='checkbox' />").data("option", "syncresize");
        $("<span />")
            .text(syncResizeTitle)
            .prepend($input)
            .appendTo($li);
        if (_grid.getOptions().syncColumnCellResize) {
          $input.attr("checked", "checked");
        }
        $li.children().wrapAll($('<label />'));
      }

      $menu
          .css("top", e.pageY - 10)
          .css("left", e.pageX - 10)
          .css("max-height", $(window).height() - e.pageY -10)
          .fadeIn(options.fadeSpeed);

      $list.appendTo($menu);
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

    function removeThisColumnEvent() {
      var menuItemName = this.data('column-id');
        var visibleColumns = getAllVisibleColumns().filter(function (column) {
          return column.column_name != menuItemName;
        });

        // Update columns
        grid.setColumns(visibleColumns);

        _self.onColumnsPick.notify({});
    }

    function moveThisColumnEvent() {
      var menuItemName = this.data('column-id');
      var visibleColumns = getAllVisibleColumns();
      var currentItem = visibleColumns.find(item => item.column_name === menuItemName);
      var currentPostion = visibleColumns.indexOf(currentItem);
      var swappedColumns;

      var menuAction = this.attr('id')
      switch(menuAction) {
        case 'move_to_right':
          if (currentPostion < visibleColumns.length - 1) {
            swappedColumns = swapWithTheFrontOne(visibleColumns, currentPostion + 1)
          }
          break;
        case 'move_to_left':
          if (currentPostion > 0) {
            swappedColumns = swapWithTheFrontOne(visibleColumns, currentPostion);
          }
          break;
        default:
          swappedColumns = visibleColumns;
          break;
      }
      // Update columns
      grid.setColumns(swappedColumns);
      grid.filterPanel.generateFilters();
    }

    function swapWithTheFrontOne(array, position) {
      [array[position - 1], array[position]] = [array[position], array[position - 1]];
      return array;
    }

    // Get all columns(visible and invisible)
    function getAllColumns() {
      return columns;
    }

    // Get all visible columns
    function getAllVisibleColumns() {
      return grid.getColumns()
    }


    ///////////////////////////////////////////////////////////
    // Ekohe Add: New methods
    ///////////////////////////////////////////////////////////

    // Ekohe Add: Customazition for handleHeaderContextMenu
    //  1. Add column-container div for MD implementation
    //  2. Add "Reset to defaults" feature
    //  3. Remove "Force Fit Columns" & "Synchronous Resizing" features

    function wulinHandleHeaderContextMenu(e, args) {
      e.preventDefault();
      $menu.empty();
      updateColumnOrder();
      columnCheckboxes = [];

      var $li, $input;

      // Ekohe Add: column-container div for MD implementation
      var $columnContainer = $("<div class='column-container' />").appendTo($menu);

      // Append columns checkbox
      for (var i = 0; i < columns.length; i++) {
        $li = $("<li />").appendTo($columnContainer);
        // Ekohe Edit: MD implementation
        // $input = $("<input type='checkbox' />").data("column-id", columns[i].id);
        $input = $("<input type='checkbox' />")
          .attr({ id: 'columnpicker_' + i, name: columns[i].field })
          .appendTo($li);
        columnCheckboxes.push($input);

        if (grid.getColumnIndex(columns[i].id) != null) {
          $input.attr("checked", "checked")
                // Ekohe Add: MD implementation
                .addClass("filled-in");
        }

        // Ekohe Edit: MD implementation
        $("<span />")
          .attr("for", "columnpicker_" + i)
          .text(columns[i].name)
          .appendTo($li);

        $li.children().wrapAll($('<label />'));
      }

      // Ekohe Add
      // Addpend "Reset to defaults" checkbox
      $("<hr/>").appendTo($menu);
      var $a = $("<a id='reset_to_default' href='#' />").appendTo($menu);
      var $icon = $("<i class='material-icons'>replay</i>").appendTo($a);
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

      // Ekohe Edit: MD implementation
      $menu
        // .css("top", e.pageY - 10)
        .css("top", e.pageY + 10)
        .css("left", e.pageX - 10)
        // .css("max-height", $(window).height() - e.pageY -10)
        .fadeIn(options.fadeSpeed);
    }

    // Ekohe Add: Customazition for updateColumn
    //  1. Remove "Force Fit Columns" & "Synchronous Resizing" features

    function wulinUpdateColumn(e) {
      // Use specifc class to identify columnpicker since e.target
      // is recognized as label (should be input) here.
      // TODO: Use e.target instead of using columnpicker element

      var visibleColumns = [];
      $.each($('#' + grid.name + '-columnpicker li input'), function(i, e) {
        if ($(this).is(":checked")) {
          visibleColumns.push(columns[i]);
          $(this).addClass("filled-in");
        }
      });
      grid.setColumns(visibleColumns);

      // Ekohe Add: Reset filters
      $(grid.getHeaders()).find('input').keyup();
      grid.filterPanel.generateFilters();
    }

    function getMenu() {
      return $menu;
    }

    function getColumnCheckboxes() {
      return columnCheckboxes;
    }

    init(_grid);

    // Ekohe Modify: Use extend instead of returning to set APIs to this
    $.extend(this, {
    // return {
      "init": init,
      "getAllColumns": getAllColumns,
      "destroy": destroy,
      "onColumnsPick": new Slick.Event(),
      // Ekohe Add
      "onColumnsChanged": onColumnsChanged,
      "removeThisColumnEvent": removeThisColumnEvent,
      "moveThisColumnEvent": moveThisColumnEvent,
    });
  }

  // Slick.Controls.ColumnPicker
  $.extend(true, window, { Slick:{ Controls:{ ColumnPicker:SlickColumnPicker }}});
})(jQuery);
