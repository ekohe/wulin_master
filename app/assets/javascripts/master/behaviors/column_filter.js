// two columns, has_many relationship

WulinMaster.behaviors.ColumnFilter = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onDataLoaded",

  subscribe: function(target) {
    var self = this;
    target.loader[this.event].subscribe(function(){ self.handler(); });
  },

  unsubscribe: function() {

  },

  handler: function() {
    // we can use this to get all context
  }

});

WulinMaster.BehaviorManager.register("column_filter", WulinMaster.behaviors.ColumnFilter);