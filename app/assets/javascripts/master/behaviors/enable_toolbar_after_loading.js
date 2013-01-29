// Enable toolbar items after data loaded

WulinMaster.behaviors.enableToolbarAfterLoading = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onDataLoaded",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target.loader[this.event].subscribe(function(){ self.handler(); });
  },

  unsubscribe: function() {

  },

  handler: function() {
    var $toolbar_items = this.grid.container.find(".toolbar_item a");
    $.each($toolbar_items, function(){
      if(!$(this).hasClass('toolbar_manually_enable')) $(this).removeClass("toolbar_icon_disabled");
    });
  }

});

WulinMaster.BehaviorManager.register("enable_toolbar_after_loading", WulinMaster.behaviors.enableToolbarAfterLoading);