(function($) {
	function GridManager() {
		var gridElementPrefix = "#grid_";
		var gridElementSuffix = " .grid";
		var pagerElementSuffix = " .pager";
		var filterTriggerElementSuffix = " .grid-header .filter_toggle";
		var deleteElementSuffix = ' .grid-header .delete_button';
		var createElementSuffix = ' .grid-header .create_button';

		var grids = [];
    var createdIds = [];
		var options = {
			editable: true,
			enableAddRow: false,
			enableCellNavigation: true,
			asyncEditorLoading: false,
			autoEdit: false,
			cellFlashingCssClass: "master_flashing"
		}

		function init() {
		}

		function getEditorForType(type){
			switch(type){
				case "string":
				return TextCellEditor;
				case "text":
				return LongTextCellEditor;
				case "datetime":
				return DateCellEditor2;
				default:
				return TextCellEditor;
			}
		}
		
		function appendEditor(columns){
		  for(var i in columns){
				if(columns[i].editable == true) {
					columns[i].editor = getEditorForType(columns[i].type);
					if(columns[i].type == "datetime") {
						columns[i].formatter = DateCellFormatter;
						columns[i].DateShowFormat = "yy-mm-dd";
					}
				}
			}
		}

		function createNewGrid(name, path, columns, states) {
			var gridElement = $(gridElementPrefix + name + gridElementSuffix);
			
			// Append editor attribute to columns
			appendEditor(columns);
		
			// restore the order states to columns
		  columns = GridStatesManager.restoreOrderStates(columns, states["order"]);
		  // restore the width states to columns
		  GridStatesManager.restoreWidthStates(columns, states["width"])
      
      // Set Loader
			var loader = new Slick.Data.RemoteModel(path, columns);
			// So we know who is the owner
			// loader.connectionManager.remoteModel = loader;

			// ------------------------- Create Grid ------------------------------------
			var grid = new Slick.Grid(gridElement, loader.data, columns, options);
			loader.setGrid(grid);
		  
			// create loading indicator on the activity panel
			loader.setLoadingIndicator(createLoadingIndicator(gridElement));
			
			// restore the sorting states to grid
		  GridStatesManager.restoreSortingStates(loader, states["sort"]);
			
			// Set Pager
			var pagerElement = $(gridElementPrefix + name + pagerElementSuffix);
			var pager = new Slick.Controls.Pager(loader, grid, pagerElement);
      
      // Set Filter
			var filterTriggerElement = $(gridElementPrefix + name + filterTriggerElementSuffix);
			var filterPanel = new Slick.FilterPanel(grid, loader, filterTriggerElement);
			
			// Set connection manager
			// var connectionManager = new ConnectionManager();
			
			// Set grid body height after rendering
			setGridBodyHeight(gridElement);
			grid.resizeCanvas();

			// Load the first page
			grid.onViewportChanged(); 		
					
			// Append necessary attributes to the grid
			var grid_attributes = {name: name, loader: loader, path: path, pager: pager, filterPanel: filterPanel};
      for(var attr in grid_attributes) {
        grid[attr] = grid_attributes[attr];
      }
      
      // delete old grid if exsisting, then add grid
			for(var i in grids){
				if(grid.name == grids[i].name){
					grids.splice(i, 1);
				}
			}
			grids.push(grid);
      
      
      // ------------------------------- customized methods for the grid ----------------------------－－－－－－－
			
			// get row by record.id
			grid.getRowByRecordId = function(id) {
			  var data = this.loader.data;
			  for(var i in data) {
			    if (data.hasOwnProperty(i) && i !== 'length' && data[i].id == id) { return this.getRowAt(i); };
			  }
			}
			
			
			// ------------------------------- register events on the grid ----------------------------------------
			// register grid events
			grid.onCellChange = function(currentRow, currentCell, item) {
				Requests.updateByAjax(this, item);
			};
			
			// handle multiple grids: select one,release previou one
			grid.onClick = function(currentRow, currentCell, item) {
				$.each(grids, function(){
					if (this.name != grid.name)
						this.setSelectedRows([]);
				})
			};
			
			// ------------------------------ register callbacks for handling grid states ------------------------
			GridStatesManager.onStateEvents(grid);
			
			// ------------------------------ button events -----------------------------------------
			
			// Delete along delete button
			var deleteElement = $(gridElementPrefix + name + deleteElementSuffix);
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
			var createButtonElement = $(gridElementPrefix + name + createElementSuffix);
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
			var truncateThreshold = 35;
			var parent = gridElement.parent(".grid_container");
			var id = parent.attr("id");
			var title = $.trim(parent.find(".grid-header h2").text());
			if (title.length > truncateThreshold) {
				title = title.substring(0, truncateThreshold-2) + "..."
			}
			var indicators = $("#activity #indicators");

			// Remove init indicator if it exists.
			indicators.find("#init_menu_indicator").remove();

			var indicator = indicators.find(".loading_indicator#" + id);

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
		  var container = gridElement.parent(".grid_container");
		  var ch = container.height();
		  var hh = container.find(".grid-header").height();
	    var ph = container.find(".pager").height();
	    var gh = ch - hh - ph;
	    gridElement.css("height", gh - 1);
		}

		function resizeGrids() {		  
			$.each(grids, function() {
			  var gridElement = $(gridElementPrefix + this.name + gridElementSuffix);
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
	