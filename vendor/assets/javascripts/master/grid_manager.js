(function($) {
	function GridManager() {
		var gridElementPrefix = "#grid_";
		var gridElementSuffix = " .grid";
		var pagerElementSuffix = " .pager";
		var filterTriggerElementSuffix = " .grid-header .filter_toggle";
		var deleteElementSuffix = ' .grid-header .delete_button';
		var createElementSuffix = ' .grid-header .create_button';

		var grids = [];

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

		function createNewGrid(name, path, columns) {
			gridElement = $(gridElementPrefix + name + gridElementSuffix);

			// append editor attribute to columns
			for(i in columns){
				if(columns[i].editable == true) {
					columns[i].editor = getEditorForType(columns[i].type);
					if(columns[i].type == "datetime") {
						columns[i].formatter = DateCellFormatter;
						columns[i].DateShowFormat = "yy-mm-dd";
					}
				}
			}

			loader = new Slick.Data.RemoteModel(path, columns);
			// So we know who is the owner
			// loader.connectionManager.  remoteModel = loader;

			grid = new Slick.Grid(gridElement, loader.data, columns, options);
			loader.setGrid(grid);

			// register grid events
			grid.onCellChange = function(currentRow, currentCell, item) {
				update_record(this.store, item);
			};
			
			// handle multiple grids: select one,release previou one
			grid.onClick = function(currentRow, currentCell, item) {
				$.each(grids, function(i,hash){
					if (hash.name != name)
						hash.grid.setSelectedRows([]);
				})
			};
			
			// Delete along delete button
			deleteElement = $(gridElementPrefix + name + deleteElementSuffix);
			deleteElement.click(function() {
				var ids = Tools.selectIds(name);
				if (ids && confirm("Are you sure to do this?")) {
					deleteRecord(getGrid(name).grid, ids);
				} else {
					alert("Please select more than one row first!");
				}
			});
			
			// keypress action
			$(document).keypress(function(e){
				var isOpen = Tools.isOpen();
				if (isOpen) {
					return true;
				} else {
					if (e.which == 100) {  // keypress 'D' for delete
						var ids = Tools.selectIds(name);
						if (ids && confirm("Are you sure to do this?")) {
							deleteRecord(getGrid(name).grid, ids);
							return false;
						}
						return false;
          } else if (e.which == 99) {  // keypress 'C' for show dialog
						var gridContainers = $('.grid_container');
						var	gridSize = gridContainers.size();
						if (gridSize > 0) {
							if (gridSize == 1) {
								var gridName = gridContainers.attr('id').split('grid_')[1];
								Tools.openDialog(gridName);
							} else if (Tools.selectIds(name)) {
								Tools.openDialog(name);
							}
							return false;
						}
						return false;
					} else {
						return true;
					}
				}	
      });

			
			// Create action
			createButtonElement = $(gridElementPrefix + name + createElementSuffix);
			createButtonElement.click(function() {
				Tools.openDialog(name);
			});
			// Click 'Create' button
			$('#' + name + '_submit').click(function() {
				Tools.createByAjax(name, false);
			  return false;
			});
			// Click 'Create and Continue' button
			$('#' + name + '_submit_continue').click(function() {
				Tools.createByAjax(name, true);
			  return false;
			});
		
			// Set connection manager
			connectionManager = new ConnectionManager();


			pagerElement = $(gridElementPrefix + name + pagerElementSuffix);
			pager = new Slick.Controls.Pager(loader, grid, pagerElement);

			filterTriggerElement = $(gridElementPrefix + name + filterTriggerElementSuffix);
			filterPanel = new Slick.FilterPanel(grid, loader, filterTriggerElement);

			loader.setLoadingIndicator(createLoadingIndicator(gridElement));

			// Load the first page
			grid.onViewportChanged();

			var grid_object = {name: name, path: path, columns: columns, loader: loader, grid: grid, pager: pager, filterPanel: filterPanel};
			grid.store = grid_object;

			// delete old grid if exsisting
			for(i in grids){
				if(grid_object.name == grids[i].name){
					grids.splice(i, 1);
				}
			}
			grids.push(grid_object);
		}

		function update_record(store, item) {
			delete item.slick_index;
			// format item data like time, date
			format_data(item);
			// put ajax
			$.ajax({
				type: "POST",
				url: store.path + "/" + item.id + ".json",
				data: decodeURIComponent($.param({_method: 'PUT', item: item, authenticity_token: window._token})),
				success: function(msg) {
					if(msg.success == true) {

					} else {
						alert(msg.error_message);
						store.loader.reloadData();
					}
				}
			});
		}

		// Delete rows along ajax 
		function deleteRecord(grid, ids) {
			$.ajax({
				type: 'POST',
				url: grid.store.path + '/' + ids + '.json',
				data: decodeURIComponent($.param({_method: 'DELETE', authenticity_token: window._token})),
				success: function(msg) {
					if(msg.success == true) {
						grid.setSelectedRows([]);
						grid.store.loader.reloadData();
						$('.notic_flash').remove();
						var recordSize = ids.split(',').length;
						var recordUnit = recordSize > 1 ? 'records' : 'record';
						$('#indicators').before('<div class="notic_flash">' + recordSize + ' ' + recordUnit + ' has been deleted!</div>');
						$('.notic_flash').fadeOut(7000);
					} else {
						alert(msg.error_message);
					}
				}
			})
		}
		
		//Common tools
		var Tools = {
			// Record create along ajax
			createByAjax: function(name, continue_on) {
				var grid = getGrid(name).grid;
				var createFormElement = $('#new_' + name);
				// clear all the error messages
				createFormElement.find(".field_error").text("");
				$.ajax({
	     		type:'POST',
	     		url: grid.store.path + '.json',
	     		data: createFormElement.serialize() + "&authenticity_token=" + window._token,
	     		success: function(request) { 
						if (request.success == true) {
							Tools.resetForm(name);
							if (!continue_on) { Tools.closeDialog(name); }
							grid.store.loader.reloadData();
							// flash new create row
							var createdIndex = Tools.findCreatedIndex(name, request.id);
							setTimeout(function(){
								grid.flashCell(createdIndex, null, 300)
							}, 500)
							
						} else {
							for(key in request.error_message){
							  var errors = "";
							  for(i in request.error_message[key]){
							    errors += (request.error_message[key][i] + " ")
							  }		  
							  createFormElement.find(".field[name=" + key + "]").find(".field_error").text(errors);
							}
						}
					}
	   		});
			},
			
			// Select record id attribute form grid
			selectIds: function(name){
				var _gird = getGrid(name).grid;
				var selectedIndexs = _gird.getSelectedRows();
				if (selectedIndexs.length > 0) {
					var ids = selectedIndexs.map(function(n, i) { 
						var item = _gird.store.loader.data[n];
						return item['id']; 
						}).join();
					return ids;
				} else {
					return false;
				}
			},
			
			// find the row after a new row was created
			findCreatedIndex: function(name, recordId) {
				return $(gridElementPrefix + name + " .slick-row").size();
			},
			
			// return true if the dialog of grid with "name" is open, unless return false 
			isOpen: function(name) {
		 		return ($(".ui-dialog:visible").size() > 0);
			},
			
			// Select grid names
			selectGridNames: function() {
				var gridContainers = $(".grid_container");
				return $.map( gridContainers, function(container){
					var gridName = $(container).attr("id").split("grid_")[1].trim();
					if (gridName != '' && gridName != null && gridName != undefined)
				  	return gridName;
				});
			},
			
			// Reset form
			resetForm: function(name) {
				$(':input','#new_' + name).not(':button, :submit, :reset, :hidden').val('').removeAttr('checked').removeAttr('selected');
			},
			
			// Create and open dialog
			openDialog: function(name) {
				$( '#' + name + '-form' ).dialog({
					height: 300,
					width: 500,
					show: "blind",
					modal: true,
					open: function(event, ui) { $( '#' + name + '-form input:text' ).first().focus(); },
					close: function(event, ui) { 
					  $(this).find("input:text").val("");
					  $(this).find(".field_error").text(""); 
					}
				});
			},
			
			// Close dialog
			closeDialog: function(name) {
				$( '#' + name + '-form' ).dialog( "close" );
			}
			
		};
		

		function format_data(item) {}

		function createLoadingIndicator(gridElement) {
			var truncateThreshold = 35;
			var parent = gridElement.parent(".grid_container");
			var id = parent.attr("id");
			var title = parent.find(".grid-header h2").text().trim();
			if (title.length > truncateThreshold) {
				title = title.substring(0, truncateThreshold-2) + "..."
			}
			var indicators = $("#activity #indicators");

			// Remove init indicator if it exists.
			indicators.find("#init_menu").remove();

			var indicator = indicators.find(".loading_indicator#" + id);

			if (indicator.length == 0) {
				indicator = $(buildIndicatorHtml(id, title, "")).appendTo(indicators);
				// Init counter
				indicator.data("requestCount", 0);
			}

			return indicator;
		}

		function buildIndicatorHtml(id, title){
			return "<div class='loading_indicator' id='" + id + "'><div class='loading_text'>"+ title +"</div><div class='loading_bar' /><div class='loading_stats' /></div>"
		}

		function getGrid(name) {
			var theGrid = null;

			$.each(grids, function(index, gridHash) {
				if (gridHash.name==name)
				theGrid = gridHash;
			});

			return theGrid;
		}

		function resizeGrids() {
			$.each(grids, function(index, grid) {
				grid.grid.resizeCanvas();
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