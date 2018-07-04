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
      rowHeight: 30
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

    function createNewGrid(name, model, screen, path, filters, columns, states, actions, behaviors, extend_options, user_id) {
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
          loadOnce: true,
          useRowClick: options.rowDetail.useRowClick,
          panelRows: options.rowDetail.panelRows,
          cssClass: options.rowDetail.cssClass,
          preTemplate: options.rowDetail.loadingTemplate,
          postTemplate: window['RowDetailTemplates'][options.rowDetail.postTemplate],
          process: asyncRespDetailView
        });

        // push the plugin as the first column
        columns.unshift(rowDetailView.getColumnDefinition());
      }

      // ------------------------- Create Grid ------------------------------------
      grid = new WulinMaster.Grid(gridElement, loader.data, columns, options);

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
        options: options
      };
      for(var attr in gridAttrs) {
        grid[attr] = gridAttrs[attr];
      }

      // Set selection model
      grid.setSelectionModel(new WulinMaster.RowSelectionModel());

      // Set ColumnPicker
      var columnpicker = new Slick.Controls.ColumnPicker(columns, grid, user_id, options);

      // Set FilterPanel
      var filterPanel = new WulinMaster.FilterPanel(grid, grid.loader, grid.states["filter"]);
      grid.filterPanel = filterPanel;

      // Load data into grid
      loader.setGrid(grid);

      // Set Pager
      pagerElement = $(gridElementPrefix + name + pagerElementSuffix);
      pager = new WulinMaster.Pager(loader, grid, pagerElement);
      grid.pager = pager;

      // Ekohe Delete: Stop setting indicator (Create progress bar as indicator in connection instead)
      // Create loading indicator on the activity panel, if not eager loading, hide the indicator
      // var isHide = (grid.options.eagerLoading === false);
      // loader.setLoadingIndicator(createLoadingIndicator(gridElement, isHide));

      // Set default sorting state
      if (options.defaultSortingState) {
        grid.setSortColumn(options.defaultSortingState.column, options.defaultSortingState.direction == 'ASC');
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
