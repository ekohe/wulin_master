var GridStatesManager = {
  // do ajax save
  saveStates: function(gridName, type, value){
    if(gridName) {
      var state_value = {}
      var url = "/wulin_master/grid_states_manages/save"

      if (!type) { state_value['order'] = {} }
      else if (typeof type == 'string') { state_value[type] = value }
      else if (typeof type == 'object' && !$.isArray(type)) { state_value = type }

      return $.post(url, {
        grid_name: gridName,
        state_value: JSON.stringify(state_value),
        authenticity_token: window._token
      });
    }
  },

  // grid events
  onStateEvents: function(grid) {
    var self = this;

    // save columns width when columns resized
    grid.onColumnsResized.subscribe(function(){
      var widthJson = {};
      $.each(this.getColumns(), function(index, column){
        widthJson[column.id] = column.width;
      });
      self.saveStates(grid.name, "width", widthJson);
    });

    // save columns sorting info when columns sorted
    grid.onSort.subscribe(function(e, args){
      //
      //subscribe onSort event, will perform a request to save the grid states
      //
      var loader = grid.loader, sortJson = {};
      sortJson["sortCol"] = loader.getSortColumn();
      sortJson["sortDir"] = loader.getSortDirection();
      // update sort state and save it to db
      grid.states["sort"] = {sortCol: sortJson["sortCol"], sortDir: sortJson["sortDir"]};
      self.saveStates(grid.name, "sort", sortJson);
    });

    // save columns order when columns re-ordered
    grid.onColumnsReordered.subscribe(function(e, args){
      var columns = this.getColumns();
      var orderJson = {};
      $.each(columns, function(index, column){
        orderJson[index] = column.id;
      });

      // Also update pinnedColumns order based on current column positions
      var currentPinnedColumns = this.getOptions().pinnedColumns || [];
      if (currentPinnedColumns.length > 0) {
        // Rebuild pinnedColumns array in the order they appear in the grid
        var newPinnedColumns = [];
        $.each(columns, function(index, column){
          var colName = column.column_name || column.id;
          if (currentPinnedColumns.indexOf(colName) !== -1) {
            newPinnedColumns.push(colName);
          }
        });
        // Save both order and updated pinnedColumns
        self.saveStates(grid.name, {order: orderJson, pinnedColumns: newPinnedColumns});
      } else {
        self.saveStates(grid.name, "order", orderJson);
      }
    });

    // save pinned columns when columns are pinned/unpinned
    grid.onColumnsPinned.subscribe(function(e, args){
      var pinnedColumns = args.pinnedColumns || [];

      // Also save the new order since pinning changes column order
      var orderJson = {};
      $.each(grid.getColumns(), function(index, column){
        orderJson[index] = column.id;
      });

      // Save both pinnedColumns and order in a single request to avoid race condition
      self.saveStates(grid.name, {pinnedColumns: pinnedColumns, order: orderJson});
    });

    // save filter states when input filter value
    if(grid.filterPanel) {
      grid.filterPanel.onFilterLoaded.subscribe(function(e, args){
        if (args.filterData.length == 0) {
          self.saveStates(grid.name, "filter", null);
        } else {
          var filterJson = {};
          $.each(args.filterData, function(index,data){
            filterJson[data['id']] = data['value'];
          });
          self.saveStates(grid.name, "filter", filterJson);
        }
      });

      grid.filterPanel.onFilterPanelClosed.subscribe(function(e, args){
        $(grid.getHeaderRow()).find('input[type="text"]').val('');
        self.saveStates(grid.name, "filter", {});
      });
    }

    // save columns visibility when pick columns
    if(grid.picker){
      grid.picker.onColumnsPick.subscribe(function(e, args){
        var hiddenArr = [], hiddenJson = {}, visibilityColumns = grid.getColumns();

        // Regenerate Filter panel
        if(grid.filterPanel) {
          grid.filterPanel.generateFilters();
        }

        visibilityColumns = $.map(visibilityColumns, function(n, i){
            return n.id;
        });
        allColumns = $.map(grid.columns, function(n, i){
            return n.id;
        });

        hiddenArr = $.grep(allColumns, function(n, i){
            return visibilityColumns.indexOf(n) < 0;
        });

        $.each(hiddenArr, function(index, column){
            hiddenJson[index] = column;
        });
        self.saveStates(grid.name, "visibility", hiddenArr);
      });
    }
  },

  // Restore columns order states
  restoreOrderStates: function(columns, orderStates){
    if(!orderStates) return columns;

    var new_columns = [], i, j, k;
    // push other columns according to states
    for(j in orderStates){
      for(k in columns) {
        if(columns[k].id == orderStates[j]){
          new_columns.push(columns[k]);
          break;
        }
      }
    }
    // push columns that are not in the state in abritrary order
    for(i in columns) {
      var found = false;
      for(j in new_columns) {
        if (columns[i].id == new_columns[j].id) {
          found = true;
        }
      }
      if (found === false) {
        new_columns.push(columns[i]);
      }
    }
    return new_columns;
  },

  // Restore columns visibility states
  restoreVisibilityStates: function(columns, visibilityStates) {
    if(!visibilityStates) return false;

    // push visible columns according to states
    for(var i in columns){
      var visible = true;
      for(var j in visibilityStates){
        if(columns[i].id == visibilityStates[j]){
          visible = false;
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
          columns[j].width = parseInt(widthStates[i], 10);
          break;
        }
      }
    }
  },

  // Restore columns sorting states
  restoreSortingStates: function(grid, loader, sortingStates) {
    if(sortingStates){
      grid.setSortColumn(sortingStates["sortCol"], sortingStates["sortDir"] == 1);
      if(grid.options.eagerLoading !== false){
        loader.setSort(sortingStates["sortCol"], sortingStates["sortDir"]);
      }
    }
  },

  // Attach state filters
  applyFilters: function(originalFilters, filterStates) {
    if (filterStates) {
      originalFilters = originalFilters || [];
      $.each(filterStates, function(k, v){
        originalFilters.push({column: k, value: v, operator: 'equals'});
        //path += "&filters[][column]=" + encodeURIComponent(k) + "&filters[][value]=" + encodeURIComponent(v);
      });
    }
    return originalFilters;
  },

  // Restore pinned columns states
  restorePinnedColumnsStates: function(columns, pinnedColumnsStates, gridOptions) {
    if (!pinnedColumnsStates || !Array.isArray(pinnedColumnsStates) || pinnedColumnsStates.length === 0) {
      gridOptions.pinnedColumns = [];
      gridOptions.frozenColumn = -1;
      return columns;
    }

    // Reorder columns: pinned columns first in the order specified
    var pinnedCols = [];
    var unpinnedCols = [];

    // First, collect pinned columns in the correct order
    pinnedColumnsStates.forEach(function(pinnedColName) {
      for (var i = 0; i < columns.length; i++) {
        if (columns[i].column_name === pinnedColName || columns[i].id === pinnedColName) {
          pinnedCols.push(columns[i]);
          break;
        }
      }
    });

    // Then collect unpinned columns
    columns.forEach(function(col) {
      var isPinned = pinnedColumnsStates.indexOf(col.column_name) !== -1 ||
                     pinnedColumnsStates.indexOf(col.id) !== -1;
      if (!isPinned) {
        unpinnedCols.push(col);
      }
    });

    // Only count visible pinned columns for frozenColumn
    var visiblePinnedCount = 0;
    for (var i = 0; i < pinnedCols.length; i++) {
      if (pinnedCols[i].visible !== false) {
        visiblePinnedCount++;
      }
    }

    // Only include visible pinned columns in the pinnedColumns option
    var visiblePinnedNames = [];
    for (var j = 0; j < pinnedColumnsStates.length; j++) {
      var colName = pinnedColumnsStates[j];
      // Find the column in pinnedCols
      var col = null;
      for (var k = 0; k < pinnedCols.length; k++) {
        if (pinnedCols[k].column_name === colName || pinnedCols[k].id === colName) {
          col = pinnedCols[k];
          break;
        }
      }
      if (col && col.visible !== false) {
        visiblePinnedNames.push(colName);
      }
    }
    gridOptions.pinnedColumns = visiblePinnedNames;
    gridOptions.frozenColumn = visiblePinnedCount > 0 ? visiblePinnedCount - 1 : -1;

    return pinnedCols.concat(unpinnedCols);
  }

};

