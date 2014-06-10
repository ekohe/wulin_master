var GridStatesManager = {
  // do ajax save
  saveStates: function(gridName, type, value){
    if(gridName) {
      type = type || "order";
      vale = value || {};
      var url = "/wulin_master/grid_states_manages/save",
      data = decodeURIComponent($.param({ grid_name: encodeURIComponent(gridName),
                                        state_type: encodeURIComponent(type),
                                        state_value: value,
                                        authenticity_token: window._token }));
      $.post(url, data, function(){});
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
      var loader = grid.loader, sortJson = {};
      sortJson["sortCol"] = loader.getSortColumn();
      sortJson["sortDir"] = loader.getSortDirection();
      // update sort state and save it to db
      grid.states["sort"] = {sortCol: sortJson["sortCol"], sortDir: sortJson["sortDir"]};
      self.saveStates(grid.name, "sort", sortJson);
    });

    // save columns order when columns re-ordered
    grid.onColumnsReordered.subscribe(function(e, args){
      var orderJson = {};
      $.each(this.getColumns(), function(index, column){
        orderJson[index] = column.id;
      });

      self.saveStates(grid.name, "order", orderJson);
    });

    // save filter states when input filter value
    if(grid.filterPanel) {
      grid.filterPanel.onFilterLoaded.subscribe(function(e, args){
        var filterJson = {};
        $.each(args.filterData, function(index,data){
          filterJson[data['id']] = encodeURIComponent(data['value']);
        });
        self.saveStates(grid.name, "filter", filterJson);
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
        if(orderStates[j] != 'id' && columns[k].id == orderStates[j]){
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
      } else {
        loader.setSortWithoutRefresh(sortingStates["sortCol"], sortingStates["sortDir"]);
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
  }

};

