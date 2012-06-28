// Show scroll bar after data loading for grid which is eagerLoading false 
// (because the scroll bar was hided for this kind of grid when initialize)

WulinMaster.behaviors.showScrollAfterLoading = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onDataLoaded",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target.loader[this.event].subscribe(function(){ self.handler() });
  },

  unsubscribe: function() {

  },

  handler: function() {
    this.grid.container.find(".slick-viewport").css("overflow", "auto");
  }

});

WulinMaster.BehaviorManager.register("show_scroll_after_loading", WulinMaster.behaviors.showScrollAfterLoading);