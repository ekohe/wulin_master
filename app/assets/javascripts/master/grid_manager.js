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
      rowHeight: 25
    };

    function init() {
    }

    function getEditorForType(type){
      switch(type.toLowerCase()){
        case "string":
        return Slick.Editors.Text;
        case "text":
        return Slick.Editors.LongText;
        case "datetime":
        return DateTimeCellEditor;
        case "time":
        return TimeCellEditor;
        case "date":
        return Slick.Editors.Date;
        case "integer":
        return Slick.Editors.Integer;
        case "boolean":
        return YesNoCheckboxCellEditor;
        case "belongs_to":
        return BelongsToEditor;
        case "has_one":
        return BelongsToEditor;
        case "has_and_belongs_to_many":
        return BelongsToEditor;
        case "has_many":
        return HasManyEditor;
        default:
        return Slick.Editors.Text;
      }
    }

    function appendEditor(columns){
      var i, type_str;
      for(i=0; i<columns.length; i++){
        type_str = columns[i].type.toLowerCase();
        // 1. append editor
        if (columns[i].editor) {
          columns[i].editor = eval(columns[i].editor);
        } else if (columns[i].distinct) {
          columns[i].editor = DistinctEditor;
        } else {
          columns[i].editor = getEditorForType(columns[i].type);
        }
        // 2. append cssClass
        if(type_str == "boolean") {
          columns[i].cssClass = 'cell-effort-driven';
        }

        if(type_str == "date") {
          columns[i].formatter = StandardDateCellFormatter;
          columns[i].DateShowFormat = "yy-mm-dd";
        } else if (type_str == "boolean") {
          if(!columns[i].formatter) {
            columns[i].formatter = GraphicBoolCellFormatter;
          }
        } else if(type_str == "belongs_to" || type_str == "has_and_belongs_to_many") {
          columns[i].formatter = BelongsToFormatter;
        } else if (type_str == "has_many") {
          columns[i].formatter = HasManyFormatter;
        } else if(type_str == 'has_one' ) {
          columns[i].formatter = HasOneFormatter;
        }

        if (columns[i].simple_date) {
          columns[i].editor = Slick.Editors.Text;
          columns[i].formatter = SimpleDateFormatter;
        } else if (columns[i].simple_time) {
          columns[i].editor = columns[i].editor || Slick.Editors.Text;
          columns[i].formatter = SimpleTimeFormatter;
        }

        // 3. append formatter
        if (columns[i].formatter) {
          columns[i].formatter = eval(columns[i].formatter);
          continue;
        }
      }
    }

    function createNewGrid(name, model, screen, path, filters, columns, states, actions, behaviors, extend_options) {
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

      // Set Pager
      pagerElement = $(gridElementPrefix + name + pagerElementSuffix);
      pager = new WulinMaster.Pager(loader, grid, pagerElement);

      // Restore the order states to columns
      columns = GridStatesManager.restoreOrderStates(columns, states["order"]);
      // Restore the visibility states to columns
      GridStatesManager.restoreVisibilityStates(columns, states["visibility"]);
      visibleColumns = getVisibleColumns(columns);
      // Restore the width states to columns
      GridStatesManager.restoreWidthStates(visibleColumns, states["width"]);

      // ------------------------- Create Grid ------------------------------------
      grid = new WulinMaster.Grid(gridElement, loader.data, visibleColumns, options);

      // Append necessary attributes to the grid
      gridAttrs = {
        name: name,
        model: model,
        screen: screen,
        loader: loader,
        path: pathWithoutQuery,
        columns: visibleColumns,
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
      grid.setSelectionModel(new Slick.RowSelectionModel());

      // Set ColumnPicker
      var columnpicker = new Slick.Controls.ColumnPicker(visibleColumns, grid, options);

      // Load data into grid
      loader.setGrid(grid);

      // Create loading indicator on the activity panel, if not eager loading, hide the indicator
      var isHide = (grid.options.eagerLoading === false);
      loader.setLoadingIndicator(createLoadingIndicator(gridElement, isHide));

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
    } // createNewGrid

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

    // Remove columns which have option of visible:false when initialize the grid
    function getVisibleColumns(columns) {
      var tmp = [];
      for (var i = 0; i < columns.length; i++) {
        if (columns[i].visible != false) {
          tmp.push(columns[i]);
        }
      }
      return tmp;
    }

    init();

    return {
      // properties
      "grids": grids,

      // methods
      "createNewGrid": createNewGrid,
      "getGrid": getGrid,
      "resizeGrids": resizeGrids,
      "buildIndicatorHtml": buildIndicatorHtml
    };
  }

  $.extend(true, window, { GridManager: GridManager});
  })(jQuery);


  var gridManager = new GridManager();

  $(window).resize(function() { gridManager.resizeGrids(); });
