// cell update events

WulinMaster.behaviors.Update = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onCellChange",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target[this.event].subscribe(function(e, args){ self.handler(args); });
  },

  unsubscribe: function() {

  },

  handler: function(args) {
    // memorize the updated item in local grid
    var updated_column;
    for(var i in args.item) {
      if(i !== 'id') updated_column = i;
    }
    // send update request
    Requests.updateByAjax(this.grid, args.item);
  }

});

WulinMaster.BehaviorManager.register("update", WulinMaster.behaviors.Update);
