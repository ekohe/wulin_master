// ------------------------------------ UI tools -----------------------------------------
var Ui = {	
	// Select record id attribute form grid
	selectIds: function(grid){
	  if(grid == null) return false;
		var selectedIndexs = grid.getSelectedRows();
		if (selectedIndexs.length > 0) {
			var ids = selectedIndexs.map(function(n, i) { 
				var item = grid.store.loader.data[n];
				return item['id']; 
				}).join();
			return ids;
		} else {
			return false;
		}
	},
	
	// return true if the dialog of grid with "name" is open, unless return false 
	isOpen: function() {
 		return ($(".ui-dialog:visible").size() > 0);
	},
	
	// check if the grid is being edited
	isEditing: function() {
	  var editing = false;
	  $.each(gridManager.grids, function(){
	    if(this.isEditing()) editing = true;
	  });
	  return editing;
	},
	
	// Select grid names
	selectGridNames: function() {
		var gridContainers = $(".grid_container");
		return $.map( gridContainers, function(container){
			var gridName = $(container).attr("id").split("grid_")[1].trim();
			if (gridName)
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
			  setTimeout(function(){
    		  Ui.flashCreatedRows(name);
    		  gridManager.createdIds = [];
    	  }, 300);
			}
		});
	},
	
	// Close dialog
	closeDialog: function(name) {
		$( '#' + name + '-form' ).dialog( "close" );
		setTimeout(function(){
		  Ui.flashCreatedRows(name);
		  gridManager.createdIds = [];
	  }, 300);
	},
	
	// handle delete confirm with dialog
	deleteGrids: function(ids) {
	  $( "#confirm_dialog" ).dialog({
			modal: true,
			buttons: {
				Yes: function() {
				  Requests.deleteByAjax(Ui.findCurrentGrid(), ids);
					$( this ).dialog( "close" );
				},
				Cancle: function() {
					$( this ).dialog( "close" );
				}
			}
		});
	},
	
	// Highlight the created rows after close the dialog
	flashCreatedRows: function(name) {
	  var grid = gridManager.getGrid(name);
	  var createdRows = [];
	  $.each(gridManager.createdIds, function(){
	    createdRows.push(grid.getRowByRecordId(this));
	  });
	  $.each(createdRows, function(){
      $(this).effect( 'highlight', {}, 5000 );
	  });
	},
	
	// find the selected grid
	findCurrentGrid: function() {
	  var currentGrid = null;
	  $.each(gridManager.grids, function(){
	    if(this.getSelectedRows().length > 0) {
	      currentGrid = this;
      }
	  });
	  return currentGrid;
	}
	
};



// ------------------------- keypress action --------------------------------------
(function($) {
  $(document).keypress(function(e){
    var isEditing = Ui.isEditing();
  	var isOpen = Ui.isOpen();
  	var grid = Ui.findCurrentGrid();
  	if (isOpen || isEditing) {
  		return true;
  	} else {
  		if (e.which == 100 || e.which == 68) {  // keypress 'D' for delete
  			var ids = Ui.selectIds(grid);
  			if (ids) {
  			  Ui.deleteGrids(ids);
  			  return false;
  		  }
  			return false;
      } else if (e.which == 99 || e.which == 67) {  // keypress 'C' for show dialog
  			var	gridSize = gridManager.grids.length;
  			if (gridSize > 0) {
  				if (gridSize == 1) {
  					var gridName = gridManager.grids[0].name;
  					Ui.openDialog(gridName);
  				} else if (Ui.selectIds(grid)) {
  					Ui.openDialog(grid.name);
  				}
  				return false;
  			}
  			return false;
  		} else {
  			return true;
  		}
  	}	
  });
})(jQuery);
