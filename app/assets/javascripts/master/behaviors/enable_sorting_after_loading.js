// Enable columns sorting after data loaded

WulinMaster.behaviors.enableSortingAfterLoading = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onDataLoaded",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target.loader[this.event].subscribe(function(){ self.handler() });
  },

  unsubscribe: function() {

  },

  handler: function() {
    var columns = this.grid.getColumns();
    for(var i in columns) {
      if(columns[i]['origin_sortable'] == false) continue;
      columns[i]['sortable'] = true;
    }
  }

});

WulinMaster.BehaviorManager.register("enable_sorting_after_loading", WulinMaster.behaviors.enableSortingAfterLoading);