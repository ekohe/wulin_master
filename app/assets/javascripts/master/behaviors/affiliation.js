// master-detail grid relation, detail grid render the records which belongs to the selected row of master grid

WulinMaster.behaviors.Affiliation = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onSelectedRowsChanged",

  subscribe: function(target) {
    var self = this;

    this.detail_grids = this.detail_grids || [];
    if(this.detail_grids.indexOf(target) < 0) {
      this.detail_grids.push(target);
    }
    
    this.master_grid = gridManager.getGrid(self.master_grid_name);
    this.master_grid[this.event].subscribe(function(){ self.handler() });
  },

  unsubscribe: function() {

  },

  handler: function() {
    // get the selected id, then filter the detail grid
    var masterIds = this.master_grid.getSelectedIds();
    // if (masterIds.length != 1) return false;
    if (masterIds.length == 0) return false;

    var association_key = this.through;
    for(var i in this.detail_grids) {
      var detailGrid = this.detail_grids[i];
      // save the master relation info into detail grid
      detailGrid.master = {grid: this.master_grid, filter_column: association_key, filter_value: masterIds[0], filter_operator: this.operator};
      // apply sorting state if has
      var sortingStates = detailGrid.states["sort"];
      if(sortingStates) {
        detailGrid.loader.setSortWithoutRefresh(sortingStates["sortCol"], sortingStates["sortDir"]);
      }
      // filter the detail grid
      detailGrid.resetActiveCell();
      detailGrid.loader.addFilter(association_key, masterIds[0], this.operator);
    }
  }

});

WulinMaster.BehaviorManager.register("affiliation", WulinMaster.behaviors.Affiliation);