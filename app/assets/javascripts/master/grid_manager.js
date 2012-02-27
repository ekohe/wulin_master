
(function($) {
	function GridManager() {
		var gridElementPrefix = "#grid_",
		gridElementSuffix = " .grid",
		pagerElementSuffix = " .pager",
		filterTriggerElementSuffix = " .grid-header .filter_toggle",
		deleteElementSuffix = ' .grid-header .delete_button',
		createElementSuffix = ' .grid-header .create_button',
		updateElementSuffix = ' .grid-header .batch_update_button'
		
		grids = [],
		createdIds = [],
		defaultOptions = {
			editable: true,
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
					if(type_str == "date") {
						columns[i].formatter = StandardDateCellFormatter;
						columns[i].DateShowFormat = "yy-mm-dd";
					} else if (type_str == "boolean") {
						columns[i].formatter = BoolCellFormatter;
					}
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

		function createNewGrid(name, path, columns, states, actions, extend_options) {
		  var gridElement, loader, grid, pagerElement, pager, filterTriggerElement, filterPanel, 
		  gridAttrs, deleteElement, createButtonElement;
		  options = $.extend(defaultOptions, extend_options);

			gridElement = $(gridElementPrefix + name + gridElementSuffix);
			
			// Append editor attribute to columns
			appendEditor(columns);
      
      // Apply current filters
      path = GridStatesManager.applayFilters(path, states["filter"]);

      // Set Loader
			loader = new Slick.Data.RemoteModel(path, columns);
		
			// restore the order states to columns
      columns = GridStatesManager.restoreOrderStates(columns, states["order"]);
			// restore the visibility states to columns
		  GridStatesManager.restoreVisibilityStates(columns, states["visibility"]);
		  // restore the width states to columns
      GridStatesManager.restoreWidthStates(columns, states["width"]);
      
      // Set options along with actions
		  if (actions.indexOf('edit') == -1) {
		    options['editable'] = false;
		  } else {
		    options['editable'] = true;
		  }
			// ------------------------- Create Grid ------------------------------------
			grid = new Slick.Grid(gridElement, loader.data, columns, options);
			grid.setSelectionModel(new Slick.RowSelectionModel());
			
			loader.setGrid(grid);
		  
			// create loading indicator on the activity panel
			loader.setLoadingIndicator(createLoadingIndicator(gridElement));
			
			// restore the sorting states to grid
      GridStatesManager.restoreSortingStates(grid, loader, states["sort"]);
			
			// Set Pager
			pagerElement = $(gridElementPrefix + name + pagerElementSuffix);
			pager = new Slick.Controls.Pager(loader, grid, pagerElement);
      
      // Set Filter
			filterTriggerElement = $(gridElementPrefix + name + filterTriggerElementSuffix);
      filterPanel = new Slick.FilterPanel(grid, loader, filterTriggerElement, states["filter"]);
      
			// Set ColumnPicker
			var columnpicker = new Slick.Controls.ColumnPicker(columns, grid, options);
			
			// Set grid body height after rendering
			setGridBodyHeight(gridElement);
			grid.resizeCanvas();

			// Load the first page
			grid.onViewportChanged.notify();		
			
			pathWithoutQuery = path.split(".json")[0];
			query = path.split(".json")[1];
			// Append necessary attributes to the grid
			gridAttrs = {name: name, loader: loader, path: pathWithoutQuery, query: query, pager: pager, filterPanel: filterPanel, actions: actions, extend_options: extend_options};
      for(var attr in gridAttrs) {
        grid[attr] = gridAttrs[attr];
      }
      
      // delete old grid if exsisting, then add grid
			for(var i in grids){
				if(grid.name == grids[i].name){
					grids.splice(i, 1);
				}
			}
			grids.push(grid);
			
			
			// ------------------------------- register events on the grid ----------------------------------------			
			// cell update events
			grid.onCellChange.subscribe(function(e, args){
			  Requests.updateByAjax(this, args.item);
			});
			
			// when editor validate return false
			grid.onValidationError.subscribe(function(e,args){
			  var rs = args.validationResults;
			  if (rs.msg) {
			    displayErrorMessage(rs.msg);
			  }
			});
			
			// handle multiple grids: select one,release previou one
      grid.onClick.subscribe(function(e, args){
        $.each(grids, function(){
          if (this.name != grid.name)
            this.setSelectedRows([]);
        });
      });
			
			// ------------------------------ register callbacks for handling grid states ------------------------
      if(states)
        GridStatesManager.onStateEvents(grid);
			
			// ------------------------------ button events -----------------------------------------
			
			// Delete along delete button
			deleteElement = $(gridElementPrefix + name + deleteElementSuffix);
			deleteElement.on('click', function() {
				var ids = Ui.selectIds(grid);
				if (ids) {
				  Ui.deleteGrids(ids);
  			  return false;
				} else {
				  displayErrorMessage("Please select a record.");
				}
			});

			
			// Create action
			createButtonElement = $(gridElementPrefix + name + createElementSuffix);
			createButtonElement.on('click', function() {
				Ui.openDialog(name, grid.extend_options);
			});
			// Click 'Create' button
			$('#' + name + '_submit').on('click', function() {
				Requests.createByAjax(grid, false);
			  return false;
			});
			// Click 'Create and Continue' button
			$('#' + name + '_submit_continue').on('click', function() {
				Requests.createByAjax(grid, true);
			  return false;
			});
			
			// Batch update action
			updateButtonElement = $(gridElementPrefix + name + updateElementSuffix);
			updateButtonElement.on('click', function(){
			  Requests.batchUpdateByAjax(grid, true);
			  return false;
			});
			
		
		} // createNewGrid
		

		function createLoadingIndicator(gridElement) {
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
				indicator = $(buildIndicatorHtml(id, title, "")).appendTo(indicators);
				// Init counter
				indicator.data("requestCount", 0);
			}

			return indicator;
		}

		function buildIndicatorHtml(id, title){
			return "<div class='loading_indicator' id='" + id + "_indicator'><div class='loading_text'>"+ title +"</div><div class='loading_bar' /><div class='loading_stats' /></div>"
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
			'createdIds': createdIds,

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
	