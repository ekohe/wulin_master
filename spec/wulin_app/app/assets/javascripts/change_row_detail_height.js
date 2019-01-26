WulinMaster.behaviors.changeRowDetailHeight = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onClick",

  subscribe: function(target) {
    this.grid = target;
    target[this.event].subscribe(this.handler.bind(this));
  },

  unsubscribe: function() {},
  handler: function() { this.grid.rowDetailView.setPanelRows(20); }
});

WulinMaster.BehaviorManager.register("change_row_detail_height", WulinMaster.behaviors.changeRowDetailHeight);
