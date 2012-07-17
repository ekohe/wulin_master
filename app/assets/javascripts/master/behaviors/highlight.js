// highlight the selected rows

WulinMaster.behaviors.Highlight = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onDataLoaded",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target.loader[this.event].subscribe(function(){ self.handler() });
  },

  unsubscribe: function() {

  },

  handler: function() {
    var data = this.grid.getData(), selectedIndexes = [];
    for (var i in data) {
      if (data[i] && this.grid.operatedIds && this.grid.operatedIds.indexOf(data[i].id) != -1) {
        selectedIndexes.push(data[i].slick_index);
      }
    }
    // highlight selected rows, at this moment, the onSelectedRowsChanged event will be triggered so don't need to handly assign gridManager.operatedIds
    this.grid.setSelectedRows(selectedIndexes);
  }

});

WulinMaster.BehaviorManager.register("highlight", WulinMaster.behaviors.Highlight);