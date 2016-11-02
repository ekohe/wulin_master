// Disable toolbar items after grid rendered for some cases (eg: eagerLoading is false)

WulinMaster.behaviors.disableToolbarInitially = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onRendered",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target[this.event].subscribe(function(){ self.handler(); });
  },

  unsubscribe: function() {

  },

  handler: function() {
    var $toolbar_items = this.grid.container.find(".toolbar_item a");
    $toolbar_items.addClass("toolbar_icon_disabled");
  }

});

WulinMaster.BehaviorManager.register("disable_toolbar_initially", WulinMaster.behaviors.disableToolbarInitially);
