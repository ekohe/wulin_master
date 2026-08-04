var GridStatesManager = {
  // do ajax save
  saveStates: function(gridName, type, value){
    if(gridName) {
      var state_value = {}
      var url = "/wulin_master/grid_states_manages/save"

      if (!type) { state_value['order'] = {} }
      else if (typeof type == 'string') { state_value[type] = value }
      else if (typeof type == 'object' && !$.isArray(type)) { state_value = type }

      return $.ajax({
        url: url,
        type: 'POST',
        data: JSON.stringify({
          grid_name: gridName,
          state_value: state_value,
          authenticity_token: window._token
        }),
        contentType: 'application/json'
      });
    }
  },

  // Build unified columns state from current grid
  buildColumnsState: function(grid) {
    var visible = grid.getColumns();
    var visibleSet = {};
    $.each(visible, function(i, col) { visibleSet[col.id] = col; });

    var filterState = grid.states ? grid.states["filter"] : null;
    var sortCol = grid.loader ? grid.loader.getSortColumn() : null;
    var sortDir = grid.loader ? grid.loader.getSortDirection() : null;

    function makeEntry(col, isVisible) {
      var entry = {id: col.id, visible: isVisible};
      if (col.width) entry.width = col.width;
      if (filterState && filterState[col.id]) entry.filter = filterState[col.id];
      if (sortCol === col.id) entry.sort = (sortDir == 1) ? "asc" : "desc";
      return entry;
    }

    // Group hidden columns by the visible column they follow in definition order
    var hiddenAfter = {};
    var hiddenBefore = [];
    $.each(grid.allColumns, function(defIdx, col) {
      if (visibleSet[col.id]) return;
      var afterId = null;
      for (var k = defIdx - 1; k >= 0; k--) {
        if (visibleSet[grid.allColumns[k].id]) { afterId = grid.allColumns[k].id; break; }
      }
      if (afterId) {
        if (!hiddenAfter[afterId]) hiddenAfter[afterId] = [];
        hiddenAfter[afterId].push(makeEntry(col, false));
      } else {
        hiddenBefore.push(makeEntry(col, false));
      }
    });

    // Interleave: hidden-before-any, then each visible column followed by its trailing hidden group
    var result = hiddenBefore.slice();
    $.each(visible, function(i, col) {
      result.push(makeEntry(col, true));
      if (hiddenAfter[col.id]) {
        result = result.concat(hiddenAfter[col.id]);
      }
    });

    return result;
  },

  // Normalize hash-with-numeric-keys (from old form-encoded saves) to array
  normalizeColumns: function(savedColumns) {
    if (!savedColumns) return null;
    if ($.isArray(savedColumns)) return savedColumns;
    var arr = [];
    var keys = Object.keys(savedColumns).sort(function(a, b) { return parseInt(a, 10) - parseInt(b, 10); });
    for (var k = 0; k < keys.length; k++) arr.push(savedColumns[keys[k]]);
    return arr;
  },

  // Extract filter hash from columns array
  extractFilterFromColumns: function(savedColumns) {
    savedColumns = this.normalizeColumns(savedColumns);
    if (!savedColumns) return null;
    var filter = {};
    $.each(savedColumns, function(i, c) {
      if (c.filter !== undefined && c.filter !== null && c.filter !== "") {
        filter[c.id] = c.filter;
      }
    });
    return Object.keys(filter).length > 0 ? filter : null;
  },

  // Extract sort object from columns array
  extractSortFromColumns: function(savedColumns) {
    savedColumns = this.normalizeColumns(savedColumns);
    if (!savedColumns) return null;
    for (var i = 0; i < savedColumns.length; i++) {
      if (savedColumns[i].sort) {
        return {sortCol: savedColumns[i].id, sortDir: savedColumns[i].sort === "asc" ? 1 : -1};
      }
    }
    return null;
  },

  // grid events
  onStateEvents: function(grid) {
    var self = this;

    // save columns state when columns resized
    grid.onColumnsResized.subscribe(function(){
      self.saveStates(grid.name, "columns", self.buildColumnsState(grid));
    });

    // save columns state when columns sorted
    grid.onSort.subscribe(function(e, args){
      // Keep states["sort"] in sync so the affiliation behavior re-applies the
      // current sort rather than the one the page loaded with
      grid.states["sort"] = {sortCol: grid.loader.getSortColumn(), sortDir: grid.loader.getSortDirection()};
      self.saveStates(grid.name, "columns", self.buildColumnsState(grid));
    });

    // save columns state when columns re-ordered
    grid.onColumnsReordered.subscribe(function(e, args){
      // Also update pinnedColumns order based on current column positions
      var currentPinnedColumns = this.getOptions().pinnedColumns || [];
      if (currentPinnedColumns.length > 0) {
        // Rebuild pinnedColumns array in the order they appear in the grid
        var newPinnedColumns = [];
        $.each(this.getColumns(), function(index, column){
          var colName = column.column_name || column.id;
          if (currentPinnedColumns.indexOf(colName) !== -1) {
            newPinnedColumns.push(colName);
          }
        });
        // Save both columns and updated pinnedColumns
        self.saveStates(grid.name, {columns: self.buildColumnsState(grid), pinnedColumns: newPinnedColumns});
      } else {
        self.saveStates(grid.name, "columns", self.buildColumnsState(grid));
      }
    });

    // save pinned columns when columns are pinned/unpinned
    grid.onColumnsPinned.subscribe(function(e, args){
      var pinnedColumns = args.pinnedColumns || [];

      // Save both pinnedColumns and columns in a single request to avoid race condition
      // (pinning changes column order too)
      self.saveStates(grid.name, {pinnedColumns: pinnedColumns, columns: self.buildColumnsState(grid)});
    });

    // save filter states when input filter value
    if(grid.filterPanel) {
      grid.filterPanel.onFilterLoaded.subscribe(function(e, args){
        // Skip saving filter state if option is set
        if (grid.options && grid.options.skipFilterGridStateSave) return;

        var filterJson = null;
        if (args.filterData.length > 0) {
          filterJson = {};
          $.each(args.filterData, function(index,data){
            filterJson[data['id']] = data['value'];
          });
        }
        grid.states["filter"] = filterJson;
        self.saveStates(grid.name, "columns", self.buildColumnsState(grid));
      });

      grid.filterPanel.onFilterPanelClosed.subscribe(function(e, args){
        // Skip saving filter state if option is set
        if (grid.options && grid.options.skipFilterGridStateSave) return;

        $(grid.getHeaderRow()).find('input[type="text"]').val('');
        grid.states["filter"] = {};
        self.saveStates(grid.name, "columns", self.buildColumnsState(grid));
      });
    }

    // save columns state when pick columns
    if(grid.picker){
      grid.picker.onColumnsPick.subscribe(function(e, args){
        // Regenerate Filter panel
        if(grid.filterPanel) {
          grid.filterPanel.generateFilters();
        }
        self.saveStates(grid.name, "columns", self.buildColumnsState(grid));
      });
    }
  },

  // Restore order, visibility, and width from unified columns array
  restoreColumnStates: function(columns, savedColumns) {
    savedColumns = this.normalizeColumns(savedColumns);
    if (!savedColumns) return columns;

    var savedMap = {};
    $.each(savedColumns, function(i, sc) { savedMap[sc.id] = sc; });

    // Apply saved properties to each column
    for (var i in columns) {
      var saved = savedMap[columns[i].id];
      if (!saved) continue; // new column — leave definition as-is

      if (saved.visible !== undefined) columns[i].visible = (saved.visible === true || saved.visible === "true");
      if (saved.width !== undefined) columns[i].width = parseInt(saved.width, 10);
    }

    // Reorder: saved positions first, new columns appended at end
    var ordered = [];
    var used = {};
    $.each(savedColumns, function(i, sc) {
      for (var j in columns) {
        if (columns[j].id === sc.id) {
          ordered.push(columns[j]);
          used[columns[j].id] = true;
          break;
        }
      }
    });
    for (var i in columns) {
      if (!used[columns[i].id]) ordered.push(columns[i]);
    }

    return ordered;
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

