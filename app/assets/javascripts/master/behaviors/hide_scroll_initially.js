// Hide scroll bar initially for grid which is eagerLoading false, otherwise the scrolling will trigger the data loading

WulinMaster.behaviors.hideScrollInitially = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onRendered",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target[this.event].subscribe(function(){ self.handler() });
  },

  unsubscribe: function() {

  },

  handler: function() {
    this.grid.container.find(".slick-viewport").css("overflow", "hidden");
  }

});

WulinMaster.BehaviorManager.register("hide_scroll_initially", WulinMaster.behaviors.hideScrollInitially);