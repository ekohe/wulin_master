var GridStatesManager = {
  // do ajax save
  saveStates: function(gridName, type, value){
    var url = "/wulin_master/grid_states/save",
    data = decodeURIComponent($.param({ grid_name: gridName, state_type: type, state_value: value, 
                                        authenticity_token: window._token }));
    $.post(url, data, function(response){
    });
  },
  
  // grid events
  onStateEvents: function(grid) {
    var _self = this,
    originalColumnsResized, originalSort, originalColumnsReordered;
    
    // save columns width when columns resized
    grid.onColumnsResized.subscribe(function(){
      var widthJson = {};
      $.each(this.getColumns(), function(index, column){
        widthJson[column.id] = column.width;
      }); 
      _self.saveStates(grid.name, "width", widthJson);
    });
    
    // save columns sorting info when columns sorted
    grid.onSort.subscribe(function(e, args){
      var loader = grid.loader, sortJson = {};
      sortJson["sortCol"] = loader.getSortColumn();
      sortJson["sortDir"] = loader.getSortDirection();
      _self.saveStates(grid.name, "sort", sortJson);
    });
    
    // save columns order when columns re-ordered
    grid.onColumnsReordered.subscribe(function(e, args){
      var orderJson = {};
      $.each(this.getColumns(), function(index, column){
        orderJson[index] = column.id;
      });
      
      _self.saveStates(grid.name, "order", orderJson);
    });
    
    // save columns visibility when pick columns
    if(grid.picker){
      grid.picker.onColumnsPick.subscribe(function(e, args){
        var visibilityJson = {};
        $.each(grid.getColumns(), function(index, column){
          visibilityJson[index] = column.id;
        });
        
        _self.saveStates(grid.name, "visibility", visibilityJson);
      })
    }
  },
	
  // Restore columns order states
  restoreOrderStates: function(columns, orderStates){
	  if(!orderStates) return columns;
	  
	  var new_columns = [], i, j, k;
    // find id column
    for(i in columns){
      if (columns[i].id == "id"){
        new_columns.push(columns[i]);
        break;
      }
    }
		// push other columns according to states
		for(j in orderStates){
		  for(k in columns) {
		    if(columns[k].id == orderStates[j]){
		      new_columns.push(columns[k]);
		      break;
		    }
		  }
		}
		return new_columns;
	},
	
	// Restore columns visibility states
	restoreVisibilityStates: function(columns, visibilityStates) {
	  if(!visibilityStates) return false;
	  
	  // push visible columns according to states
	  for(var i in columns){
	    var visible = false;
	    for(var j in visibilityStates){
	      if(columns[i].id == visibilityStates[j]){
	        visible = true;
	        break;
	      }
	    }
	    columns[i].visible = visible;
	  }
	},
	
	// Restore columns width states
	restoreWidthStates: function(columns, widthStates) {
	  if(!widthStates) return false;
	  
    // restore width
    for(var i in widthStates){
      for(var j in columns){
        if(columns[j].id == i){
          columns[j].width = parseInt(widthStates[i]);
          break;
        }
      }
    }
	},
	
	// Restore columns sorting states
	restoreSortingStates: function(loader, sortingStates) {
	  if(sortingStates){
	    loader.setSort(sortingStates["sortCol"], sortingStates["sortDir"]);
	  }    
	}
	
}