var GridStatesManager = {
  saveStates: function(gridName, type, value){
    // do ajax save
    var url = "/wulin_master/grid_states/save";
    var data = decodeURIComponent($.param({grid_name: gridName, state_type: type, state_value: value, authenticity_token: window._token}));
    $.post(url, data, function(){
      
    });
  },
  
  onStateEvents: function(grid) {
    var that = this;
    
    var originalColumnsResized = grid.onColumnsResized;
    grid.onColumnsResized = function(){
      originalColumnsResized();
      
      var widthJson = [];
      $.each(this.getColumns(), function(index, column){
        var attr = {};
        attr[column.name] = column.width;
        widthJson.push(attr);
      }); 
      that.saveStates(grid.name, "width", widthJson)  
    };
    
    var originalSort = grid.onSort;
    grid.onSort = function(sortCol, sortAsc){
      originalSort(sortCol, sortAsc);
      
    };
    
    var originalColumnsReordered = grid.onColumnsReordered;
    grid.onColumnsReordered = function(){
      originalColumnsReordered();
      
    }
  }
}