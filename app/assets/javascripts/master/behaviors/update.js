// cell update events

WulinMaster.behaviors.Update = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onCellChange",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target[this.event].subscribe(function(e, args){ self.handler(args) });
  },

  unsubscribe: function() {

  },

  handler: function(args) {
    Requests.updateByAjax(this.grid, args.item, args.editCommand);
  }

});

WulinMaster.BehaviorManager.register("update", WulinMaster.behaviors.Update);