// master

WulinMaster.behaviors.Affiliation = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onSelectedRowsChanged",

  subscribe: function(target) {
    var self = this;
    this.detail_grid = target;
    this.master_grid = gridManager.getGrid(self.master_grid_name);

    this.master_grid[this.event].subscribe(function(){ self.handler() });
  },

  unsubscribe: function() {

  },

  handler: function() {
    // get the selected id, then filter the detail grid
    var masterIds = this.master_grid.getSelectedIds();
    if(masterIds.length != 1) return false;

    var association_key = this.through;
    this.detail_grid.loader.addFilter(association_key, masterIds[0]);
  }

});

WulinMaster.BehaviorManager.register("affiliation", WulinMaster.behaviors.Affiliation);