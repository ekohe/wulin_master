// push selected IDs to operatedIds when selected row changed

WulinMaster.behaviors.GetOperateIds = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onSelectedRowsChanged",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target[this.event].subscribe(function(){ self.handler(); });
  },

  unsubscribe: function() {

  },

  handler: function() {
    this.grid.operatedIds = this.grid.getSelectedIds();
  }

});

WulinMaster.BehaviorManager.register("get_operate_ids", WulinMaster.behaviors.GetOperateIds);