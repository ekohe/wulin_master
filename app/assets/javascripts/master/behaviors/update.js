// cell update events

WulinMaster.behaviors.Update = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onCellChange",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target[this.event].subscribe(function(e, args){ self.handler(args.item) });
  },

  unsubscribe: function() {

  },

  handler: function(item) {
    Requests.updateByAjax(this.grid, item);
  }

});

WulinMaster.BehaviorManager.register("update", WulinMaster.behaviors.Update);