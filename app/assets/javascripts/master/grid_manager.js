(function($) {
  function GridManager() {
    var gridElementPrefix = "#grid_",
    gridElementSuffix = " .grid",
    pagerElementSuffix = " .pager",

    grids = [],

    defaultOptions = {
      enableAddRow: false,
      enableCellNavigation: true,
      asyncEditorLoading: false,
      autoEdit: false,
      cellFlashingCssClass: "master_flashing",
      rowHeight: 26
    };

    function getEditorForType(type) {
      switch (type.toLowerCase()) {
        case "enum":
          return SelectEditor;
        case "string":
          return TextEditor;
        case "text":
          return TextAreaEditor;
        case "datetime":
          return DateTimeEditor;
        case "time":
          return TimeEditor;
        case "date":
          return DateEditor;
        case "integer":
          return IntegerEditor;
        case "decimal":
          return DecimalEditor;
        case "boolean":
          return YesNoCheckboxEditor;
        case "belongs_to":
          return OtherRelationEditor;
        case "has_one":
          return OtherRelationEditor;
        case "has_and_belongs_to_many":
          return OtherRelationEditor;
        case "has_many":
          return HasManyEditor;
        default:
          return TextEditor;
      }
    }

    function appendEditor(columns) {
      var i, type_str;
      for (i = 0; i < columns.length; i++) {
        type_str = columns[i].type.toLowerCase();

        // 1. append editor

        if (typeof columns[i].editor === 'string') {
          columns[i].editor = eval(columns[i].editor);
        } else if (typeof columns[i].editor === 'object') {
          columns[i].editor = columns[i].editor;
        } else if (columns[i].distinct) {
          columns[i].editor = DistinctEditor;
        } else {
          columns[i].editor = getEditorForType(columns[i].type);
        }

        // 2. append cssClass

        if (type_str == "boolean") {
          columns[i].cssClass = 'cell-effort-driven';
        }

        // 3. append formatter

        if (type_str == "boolean") {
          if (!columns[i].formatter) {
            columns[i].formatter = GraphicBoolCellFormatter;
          }
        }

        if (!columns[i].formatter) {
          columns[i].formatter = BaseFormatter;
        }

        columns[i].formatter = eval(columns[i].formatter);
        continue;
      }
    }

    function createNewGrid(name, model, screen, path, filters, columns, states, actions, behaviors, extend_options, select_toolbar_items, user_id) {
      var gridElement, options, loader, grid, pagerElement, pager, gridAttrs, originColumns;

      originColumns = deep_clone(columns);

      options = $.extend({}, defaultOptions, extend_options);

      gridElement = $(gridElementPrefix + name + gridElementSuffix);

      // Append editor attribute to columns
      appendEditor(columns);

      // Apply current filters
      filters = GridStatesManager.applyFilters(filters, states["filter"]);
      pathWithoutQuery = path.split(".json")[0];
      query = path.split(".json")[1];

      // Set Loader
      loader = new WulinMaster.Data.RemoteModel(path, filters, columns);

      // Restore the order states to columns
      columns = GridStatesManager.restoreOrderStates(columns, states["order"]);
      // Restore the visibility states to columns
      GridStatesManager.restoreVisibilityStates(columns, states["visibility"]);
      // Restore the width states to columns
      GridStatesManager.restoreWidthStates(columns, states["width"]);

      // create the row detail plugin
      if (options.rowDetail) {
        rowDetailView = new Slick.Plugins.RowDetailView({
          loadOnce: "loadOnce" in options.rowDetail ? options.rowDetail.loadOnce : true,
          useRowClick: options.rowDetail.useRowClick,
          panelRows: options.rowDetail.panelRows,
          hideRow: options.rowDetail.hideRow,
          cssClass: options.rowDetail.cssClass,
          preTemplate: options.rowDetail.loadingTemplate,
          postTemplate: window['RowDetailTemplates'][options.rowDetail.postTemplate],
          process: asyncRespDetailView
        });

        // push the plugin as the first column
        var triggerColumn = rowDetailView.getColumnDefinition();
        if (!options.rowDetail.showTriggerColumn) {
          triggerColumn.rowDetailIconVisible = false;
          triggerColumn.width = 0;
          triggerColumn.minWidth = 1;
        }
        columns.unshift(triggerColumn);
      }

      // ------------------------- Create Grid ------------------------------------
      grid = new Slick.Grid(gridElement, loader.data, columns, options);

      grid.onContextMenu.subscribe(function (e) {
        e.preventDefault();
        let $contextMenu = $(`<ul id='contextMenu' style='display:none;position:absolute' tabindex='0' />`)
        $contextMenu.appendTo($('body'));

        var cell = grid.getCellFromEvent(e);

        var $node = $(grid.getCellNode(cell.row, cell.cell));
        var text = $.trim($node.text());

        $contextMenu
          .empty()
          .data({ row: cell.row, copiedText: text })
          .css('top', e.pageY)
          .css('left', e.pageX)
          .show()
          .focus();

        let copyItem = `<li id='contextMenuCopy'><i class='material-icons'>content_copy</i>Copy Cell</li>`;
        $(copyItem).appendTo($contextMenu);
        let contextActions = grid.select_toolbar_items
        // Put Edit in front of Delete
        let revertContextActions = contextActions.sort((a, b) => a.title[1].localeCompare(b.title[1]))

        for (let action of revertContextActions) {
          var gridAction = grid.actions.find(function (item) {
            return (
              action.title === (item.title ||
              item.name[0].toUpperCase() + item.name.slice(1))
            );
          });

          let actionName = action.title.toLowerCase();
          $contextMenuItem = $(`<li data-action-id=${gridAction.name}_action_on_${
            grid.name
          }><i class='material-icons'>${action.icon || 'help'}</i>${
            actionName[0].toUpperCase() + actionName.slice(1)
          }</li>`);
          $contextMenuItem.appendTo($contextMenu);
        }
        // For copy cell, and actions
        $('#contextMenu li').off('click').on('click', function () {
          if (this.id === 'contextMenuCopy') {
            copyStringToClipboard(text);
          } else {
            $('#' + $(this).data('action-id')).trigger('click');
          }
        });

        if ($contextMenu.parent().find('.modal.open').length == 0 ) {
            $contextMenu.off('blur').on('blur', function(){
            $contextMenu.hide();
          })
        } else {
          $('ul#contextMenu').last().prev("ul#contextMenu").hide()
          $('body').one('click',function(){
            $contextMenu.hide();
          })
        }
      });

      // Append necessary attributes to the grid
      gridAttrs = {
        name: name,
        model: model,
        screen: screen,
        loader: loader,
        path: pathWithoutQuery,
        columns: columns,
        originColumns: originColumns,
        query: query,
        container: gridElement.parent(),
        pager: pager,
        states: states,
        actions: actions,
        behaviors: behaviors,
        select_toolbar_items: select_toolbar_items,
        options: options
      };
      for(var attr in gridAttrs) {
        grid[attr] = gridAttrs[attr];
      }

      // Set rowDetailView
      if (options.rowDetail) { grid.rowDetailView = rowDetailView; }

      // Set selection model
      grid.setSelectionModel(new Slick.RowSelectionModel());

      // Set ColumnPicker
      var columnpicker = new Slick.Controls.ColumnPicker(columns, grid, user_id, options);
      grid.columnpicker = columnpicker;
      grid.allColumns = columnpicker.getAllColumns();

      // Set FilterPanel
      var filterPanel = new WulinMaster.FilterPanel(grid, grid.loader, grid.states["filter"]);
      grid.filterPanel = filterPanel;

      // Load data into grid
      loader.setGrid(grid);

      // Set Pager
      pagerElement = $(gridElementPrefix + name + pagerElementSuffix);
      pager = new Slick.Controls.Pager(loader, grid, pagerElement);
      grid.pager = pager;

      // Ekohe Delete: Stop setting indicator (Create progress bar as indicator in connection instead)
      // Create loading indicator on the activity panel, if not eager loading, hide the indicator
      // var isHide = (grid.options.eagerLoading === false);
      // loader.setLoadingIndicator(createLoadingIndicator(gridElement, isHide));

      // Set default sorting state
      if (options.defaultSortingState) {
        grid.setSortColumn(options.defaultSortingState.column, options.defaultSortingState.direction == 'ASC');
        if(options.eagerLoading !== false){
          grid.loader.setSort(options.defaultSortingState.column, options.defaultSortingState.direction == 'ASC');
        }
      }

      // Restore the sorting states to grid
      GridStatesManager.restoreSortingStates(grid, loader, states["sort"]);

      // Dispatch actions
      WulinMaster.ActionManager.dispatchActions(grid, actions);
      // Dispatch behaviors, should come first than grid.resizeCanvas, otherwise some event like onRendered can't be triggered
      WulinMaster.BehaviorManager.dispatchBehaviors(grid, behaviors);

      // Set grid body height after rendering
      setGridBodyHeight(gridElement);
      grid.initialRender();

      // Load the first page
      grid.onViewportChanged.notify();

      // Delete old grid if exsisting, then add grid
      for(var i in grids){
        if(grid.name == grids[i].name){
          grids.splice(i, 1);
        }
      }
      grids.push(grid);

      // ------------------------------ Register callbacks for handling grid states ------------------------
      if(states)
        GridStatesManager.onStateEvents(grid);

      // ------------------------------ Install some plugins -----------------------------------
      grid.registerPlugin(new Slick.AutoTooltips());
      if (options.rowDetail) { grid.registerPlugin(rowDetailView); }
    } // createNewGrid

    function asyncRespDetailView(item) {
      rowDetailView.onAsyncResponse.notify({
        'itemDetail': item
      }, undefined, this);
    }

    function createLoadingIndicator(gridElement, isHide) {
      var truncateThreshold = 35,
          parent = gridElement.parent(".grid_container"),
          id = parent.attr("id"),
          title = $.trim(parent.find(".grid-header h2").text()),
          indicators = $("#activity #indicators"),
          indicator;

      if (title.length > truncateThreshold) {
        title = title.substring(0, truncateThreshold-2) + "...";
      }

      // Remove init indicator if it exists.
      indicators.find("#init_menu_indicator").remove();
      indicator = indicators.find(".loading_indicator#" + id);

      if (indicator.length === 0) {
        indicator = $(buildIndicatorHtml(id, title, isHide)).appendTo(indicators);
        // Init counter
        indicator.data("requestCount", 0);
      }

      return indicator;
    }

    function buildIndicatorHtml(id, title, isHide){
      return "<div class='loading_indicator' id='" + id + "_indicator' style='" + (isHide ? "display:none" : '') + "'><div class='loading_text'>"+ title +"</div><div class='loading_bar' /><div class='loading_stats' /></div>";
    }

    function getGrid(name) {
      var theGrid = null;

      $.each(grids, function() {
        if (this.name == name)
        theGrid = this;
      });

      return theGrid;
    }

    copyStringToClipboard = function(str){
      // Create new element
      var el = document.createElement('textarea');
      // Set value (string to be copied)
      el.value = str;
      // Set non-editable to avoid focus and move outside of view
      el.setAttribute('readonly', '');
      el.style = {position: 'absolute', left: '-9999px'};
      document.body.appendChild(el);
      // Select text inside element
      el.select();
      // Copy text to clipboard
      document.execCommand('copy');
      // Remove temporary element
      document.body.removeChild(el);
    }

    function setGridBodyHeight(gridElement) {
      var container = gridElement.parent(".grid_container"),
      ch = container.height(),
      hh = container.find(".grid-header").height(),
      ph = container.find(".pager").height(),
      gh = ch - hh - ph;

      gridElement.css("height", gh - 1);
    }

    function resizeGrids() {
      var gridElement;
      $.each(grids, function() {
        gridElement = $(gridElementPrefix + this.name + gridElementSuffix);
        setGridBodyHeight(gridElement);
        this.resizeCanvas();
      });
    }

    return {
      // properties
      "grids": grids,

      // methods
      "getEditorForType": getEditorForType,
      "createNewGrid": createNewGrid,
      "getGrid": getGrid,
      "resizeGrids": resizeGrids,
      "buildIndicatorHtml": buildIndicatorHtml
    };
  }

  $.extend(true, window, { GridManager: GridManager });
})(jQuery);

var gridManager = new GridManager();

$(window).resize(function() { gridManager.resizeGrids(); });
