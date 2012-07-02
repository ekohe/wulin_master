// Disable sorting after grid rendered for some cases (eg: eagerLoading is false)

WulinMaster.behaviors.disableSortingInitially = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onRendered",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target[this.event].subscribe(function(){ self.handler() });
  },

  unsubscribe: function() {

  },

  handler: function() {
    var columns = this.grid.getColumns();
    for(var i in columns) {
      // remember the column which is initially unsortable
      if(columns[i]['sortable'] == false) {
        columns[i]['origin_sortable'] = false
      }
      columns[i]['sortable'] = false;
    }
  }

});

WulinMaster.BehaviorManager.register("disable_sorting_initially", WulinMaster.behaviors.disableSortingInitially);




