var GridStatesManager = {
  saveStates: function(gridName, type, value){
    // do ajax save
    var url = "/wulin_master/grid_states/save";
    var data = decodeURIComponent($.param({grid_name: gridName, state_type: type, state_value: value, authenticity_token: window._token}));
    $.post(url, data, function(response){
    });
  },
  
  onStateEvents: function(grid) {
    var that = this;
    
    // save columns width when columns resized
    var originalColumnsResized = grid.onColumnsResized;
    grid.onColumnsResized = function(){
      originalColumnsResized();
      
      var widthJson = {};
      $.each(this.getColumns(), function(index, column){
        widthJson[column.id] = column.width;
      }); 
      that.saveStates(grid.name, "width", widthJson);  
    };
    
    // save columns sorting info when columns sorted
    var originalSort = grid.onSort;
    grid.onSort = function(sortCol, sortAsc){
      originalSort(sortCol, sortAsc);
      
      var loader = grid.loader;
      var sortJson = {};
      sortJson["sortCol"] = loader.getSortColumn();
      sortJson["sortDir"] = loader.getSortDirection();
      that.saveStates(grid.name, "sort", sortJson);
    };
    
    // save columns order when columns re-ordered
    var originalColumnsReordered = grid.onColumnsReordered;
    grid.onColumnsReordered = function(){
      originalColumnsReordered();
      
      var orderJson = {};
      $.each(this.getColumns(), function(index, column){
        orderJson[index] = column.id;
      });
      
      that.saveStates(grid.name, "order", orderJson);
    }
  },
  
  restoreOrderStates: function(columns, orderStates){
	  if(!orderStates) return columns;
	  
	  var new_columns = [];
	  // find id column
	  for(var i in columns){
		  if (columns[i].id == "id"){
		    new_columns.push(columns[i]);
		    break;
		  }
		}
		// push other columns according to states
		for(var j in orderStates){
		  for(var k in columns) {
		    if(columns[k].id == orderStates[j]){
		      new_columns.push(columns[k]);
		      break;
		    }
		  }
		}
		return new_columns;
	},
	
	restoreWidthStates: function(columns, widthStates) {
	  if(!widthStates) return false;
	  
    // restore width
    for(var i in widthStates){
      for(var k in columns){
        if(columns[k].id == i){
          columns[k].width = widthStates[i];
          break;
        }
      }
    }
	},
	
	restoreSortingStates: function(loader, Sortingstates) {
	  if(Sortingstates){
	    loader.setSort(Sortingstates["sortCol"], Sortingstates["sortDir"]);
	  }    
	}
}