
(function($) {
	function GridManager() {
		var gridElementPrefix = "#grid_",
		gridElementSuffix = " .grid",
		pagerElementSuffix = " .pager",
		filterTriggerElementSuffix = " .grid-header .filter_toggle",
		deleteElementSuffix = ' .grid-header .delete_button',
		createElementSuffix = ' .grid-header .create_button',
		
		grids = [],
		createdIds = [],
		options = {
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
				return StandardDateCellEditor;
				case "integer":
				return IntegerCellEditor;
				case "boolean":
				return YesNoCheckboxCellEditor;
				case "belongs_to":
				return BelongsToEditor;
				case "has_and_belongs_to_many":
				return BelongsToEditor;
				default:
				return TextCellEditor;
			}
		}
		
		function appendEditor(columns){
		  var i;
		  for(i in columns){
				if(columns[i].editable == true) {
				  if (columns[i].editor) {
				    columns[i].editor = eval(columns[i].editor);
  				} else {
  					columns[i].editor = getEditorForType(columns[i].type);
  				}
					if(columns[i].type == "datetime") {
						columns[i].formatter = StandardDateCellFormatter;
						columns[i].DateShowFormat = "yy-mm-dd";
					} else if (columns[i].type == "boolean" || columns[i].type == "Boolean") {
						columns[i].formatter = BoolCellFormatter;
					}
				}
				if(columns[i].type == "belongs_to" || columns[i].type == "has_and_belongs_to_many" ) {
					columns[i].formatter = BelongsToFormatter;
				}
				if(columns[i].type == "boolean" || columns[i].type == "Boolean") {
					columns[i].cssClass = 'cell-effort-driven';
				}
			}
		}

		function createNewGrid(name, path, columns, states, actions) {
		  var gridElement, loader, grid, pagerElement, pager, filterTriggerElement, filterPanel, 
		  gridAttrs, deleteElement, createButtonElement;
		  
			gridElement = $(gridElementPrefix + name + gridElementSuffix);
			
			// Append editor attribute to columns
			appendEditor(columns);
		
			// restore the order states to columns
      columns = GridStatesManager.restoreOrderStates(columns, states["order"]);
			// restore the visibility states to columns
		  GridStatesManager.restoreVisibilityStates(columns, states["visibility"])
		  // restore the width states to columns
      GridStatesManager.restoreWidthStates(columns, states["width"])
      
      // Set Loader
			loader = new Slick.Data.RemoteModel(path, columns);

			// ------------------------- Create Grid ------------------------------------
			grid = new Slick.Grid(gridElement, loader.data, columns, options);
			grid.setSelectionModel(new Slick.RowSelectionModel());
			
			loader.setGrid(grid);
		  
			// create loading indicator on the activity panel
			loader.setLoadingIndicator(createLoadingIndicator(gridElement));
			
			// restore the sorting states to grid
      GridStatesManager.restoreSortingStates(loader, states["sort"]);
			
			// Set Pager
			pagerElement = $(gridElementPrefix + name + pagerElementSuffix);
			pager = new Slick.Controls.Pager(loader, grid, pagerElement);
      
      // Set Filter
			filterTriggerElement = $(gridElementPrefix + name + filterTriggerElementSuffix);
			filterPanel = new Slick.FilterPanel(grid, loader, filterTriggerElement);
			
			// Set ColumnPicker
			var columnpicker = new Slick.Controls.ColumnPicker(columns, grid, options);
			
			// Set grid body height after rendering
			setGridBodyHeight(gridElement);
			grid.resizeCanvas();

			// Load the first page
			grid.onViewportChanged.notify();		
			
			pathWithoutQuery = path.split(".json")[0]
			// Append necessary attributes to the grid
			gridAttrs = {name: name, loader: loader, path: pathWithoutQuery, pager: pager, filterPanel: filterPanel, actions: actions};
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
			deleteElement.click(function() {
				var ids = Ui.selectIds(grid);
				if (ids) {
				  Ui.deleteGrids(ids);
  			  return false;
				} else {
					alert("Please select more than one row first!");
				}
			});

			
			// Create action
			createButtonElement = $(gridElementPrefix + name + createElementSuffix);
			createButtonElement.click(function() {
				Ui.openDialog(name);
			});
			// Click 'Create' button
			$('#' + name + '_submit').click(function() {
				Requests.createByAjax(grid, false);
			  return false;
			});
			// Click 'Create and Continue' button
			$('#' + name + '_submit_continue').click(function() {
				Requests.createByAjax(grid, true);
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
	