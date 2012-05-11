WulinMaster.behaviors.ColumnFilter = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onDataLoaded",

  subscribe: function(target) {
    var that = this;
    target.loader[this.event].subscribe(function(){ that.handler() });
  },

  unsubscribe: function() {

  },

  handler: function() {
    // we can use this to get all context
  }

});

WulinMaster.BehaviorManager.register("column_filter", WulinMaster.behaviors.ColumnFilter);