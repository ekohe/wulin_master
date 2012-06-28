
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
				return TextCellEditor;
				case "text":
				return LongTextCellEditor;
				case "datetime":
				return DateTimeCellEditor;
				case "date":
				return StandardDateCellEditor;
				case "integer":
				return IntegerCellEditor;
				case "boolean":
				return YesNoCheckboxCellEditor;
				case "belongs_to":
				return BelongsToEditor;
				case "has_and_belongs_to_many":
				return BelongsToEditor;
				case "has_many":
				return HasManyEditor;
				default:
				return TextCellEditor;
			}
		}
		
		function appendEditor(columns){
		  var i, type_str;
		  for(i in columns){
		    type_str = columns[i].type.toLowerCase();
				if(columns[i].editable == true) {
				  if (columns[i].editor) {
				    columns[i].editor = eval(columns[i].editor);
  				} else {
  					columns[i].editor = getEditorForType(columns[i].type);
  				}
				}
				if (columns[i].formatter) {
					columns[i].formatter = eval(columns[i].formatter);
				} 
				if(type_str == "date") {
					columns[i].formatter = StandardDateCellFormatter;
					columns[i].DateShowFormat = "yy-mm-dd";
				} else if (type_str == "boolean") {
					columns[i].formatter = BoolCellFormatter;
				}
				if(type_str == "belongs_to" || type_str == "has_and_belongs_to_many") {
					columns[i].formatter = BelongsToFormatter;
				}
				if (type_str == "has_many") {
					columns[i].formatter = HasManyFormatter;
				}
				if(type_str == 'has_one' ) {
					columns[i].formatter = HasOneFormatter;
				}
				if(type_str == "boolean") {
					columns[i].cssClass = 'cell-effort-driven';
				}
			}
		}

		function createNewGrid(name, model, screen, path, columns, states, actions, behaviors, extend_options) {
		  var gridElement, loader, grid, pagerElement, pager, filterTriggerElement, filterPanel, operatedIds = [],
		  gridAttrs, deleteElement, createButtonElement, originColumns;
		  
      originColumns = clone(columns);

		  options = $.extend({}, defaultOptions, extend_options);

			gridElement = $(gridElementPrefix + name + gridElementSuffix);

			// Append editor attribute to columns
			appendEditor(columns);
      
      // Apply current filters
      path = GridStatesManager.applayFilters(path, states["filter"]);
      pathWithoutQuery = path.split(".json")[0];
			query = path.split(".json")[1];

      // Set Loader
			loader = new Slick.Data.RemoteModel(path, columns);

			// Set Pager
			pagerElement = $(gridElementPrefix + name + pagerElementSuffix);
			pager = new Slick.Controls.Pager(loader, grid, pagerElement);

			// Restore the order states to columns
      columns = GridStatesManager.restoreOrderStates(columns, states["order"]);
			// Restore the visibility states to columns
		  GridStatesManager.restoreVisibilityStates(columns, states["visibility"]);
		  // Restore the width states to columns
      GridStatesManager.restoreWidthStates(columns, states["width"]);

			// ------------------------- Create Grid ------------------------------------
			grid = new Slick.Grid(gridElement, loader.data, columns, options);

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
				operatedIds: operatedIds, 
				states: states, 
				filterPanel: filterPanel, 
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
			var columnpicker = new Slick.Controls.ColumnPicker(columns, grid, options);

			// Load data into grid
			loader.setGrid(grid);
		  
			// Create loading indicator on the activity panel, if not eager loading, hide the indicator
			var isHide = (grid.options.eagerLoading == false);
			loader.setLoadingIndicator(createLoadingIndicator(gridElement, isHide));
			
			// Hide the scroll if eagerLoading false, otherwise the data will load if you scroll the grid
			if(isHide) {
				grid.container.find(".slick-viewport").css("overflow", "hidden");
			}
			
			// Restore the sorting states to grid
      GridStatesManager.restoreSortingStates(grid, loader, states["sort"]);
      
			// Set grid body height after rendering
			setGridBodyHeight(gridElement);
			grid.resizeCanvas();

			// Load the first page
			grid.onViewportChanged.notify();		
      
      // Dispatch actions
      WulinMaster.ActionManager.dispatchActions(grid, actions);
      // Dispatch behaviors
			WulinMaster.BehaviorManager.dispatchBehaviors(grid, behaviors);
      
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
        
		} // createNewGrid
		
		function clone(myObj){
      if(typeof(myObj) != 'object') return myObj;
      if(myObj == null) return myObj;

      var myNewObj = new Object();

      for(var i in myObj)
         myNewObj[i] = clone(myObj[i]);

      return myNewObj;
    }
		

		function createLoadingIndicator(gridElement, isHide) {
			var truncateThreshold = 35,
			parent = gridElement.parent(".grid_container"),
			id = parent.attr("id"),
			title = $.trim(parent.find(".grid-header h2").text()),
			
			indicators = $("#activity #indicators"), 
			indicator;
			
			if (title.length > truncateThreshold) {
				title = title.substring(0, truncateThreshold-2) + "..."
			}

			// Remove init indicator if it exists.
			indicators.find("#init_menu_indicator").remove();
			indicator = indicators.find(".loading_indicator#" + id);

			if (indicator.length == 0) {
				indicator = $(buildIndicatorHtml(id, title, isHide)).appendTo(indicators);
				// Init counter
				indicator.data("requestCount", 0);
			}

			return indicator;
		}

		function buildIndicatorHtml(id, title, isHide){
			return "<div class='loading_indicator' id='" + id + "_indicator' style='" + (isHide ? "display:none" : '') + "'><div class='loading_text'>"+ title +"</div><div class='loading_bar' /><div class='loading_stats' /></div>"
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
	