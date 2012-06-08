// master

WulinMaster.behaviors.Affiliation = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onSelectedRowsChanged",

  subscribe: function(target) {
    this.detail_grid = target;
    var self = this;
    var master_grid = gridManager.getGrid(self.master_grid_name);

    master_grid[this.event].subscribe(function(){ self.handler() });
  },

  unsubscribe: function() {

  },

  handler: function() {
    // get the selected id, then filter the detail grid
    
  }

});

WulinMaster.BehaviorManager.register("affiliation", WulinMaster.behaviors.Affiliation);