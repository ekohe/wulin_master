// master-detail grid relation, detail grid clear data when master grid has no selection

WulinMaster.behaviors.EmptyDetail = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onDataLoaded",

  subscribe: function(target) {
    var self = this;

    this.detail_grids = this.detail_grids || [];
    if(this.detail_grids.indexOf(target) < 0) {
      this.detail_grids.push(target);
    }

    this.master_grid = gridManager.getGrid(self.master_grid_name);
    if(this.master_grid) {
      this.master_grid.loader[this.event].subscribe(function(){ self.handler(); });
    }
  },

  unsubscribe: function() {

  },

  handler: function() {
    // get the selected id, then filter the detail grid
    var rows = this.master_grid.getSelectedRows();
    if(rows.length == 0) {
      for(var i=0; i< this.detail_grids.length; i++) {
        var detailGrid = this.detail_grids[i];
        detailGrid.resetActiveCell();
        detailGrid.loader.clear();
        // detailGrid.pager.resetPager();
        detailGrid.render();
      }
    }
  }

});

WulinMaster.BehaviorManager.register("empty_detail", WulinMaster.behaviors.EmptyDetail);
