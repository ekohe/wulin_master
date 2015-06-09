// When close the filter panel, clear the grid filters filtered by user (don't clear the default filter like the master filter in detail grid)

WulinMaster.behaviors.clearFilters = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onFilterPanelClosed",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    if(target.filterPanel) {
      target.filterPanel[this.event].subscribe(function(){ self.handler(); });
    }
  },

  unsubscribe: function() {

  },

  handler: function() {
    var master;
    var fulledInputs = $('input', $(this.grid.getHeaderRow()));
    fulledInputs = fulledInputs.filter(function() { return this.value != ""; });

    if (fulledInputs.size() > 0) {
      master = this.grid.master;
      // if the grid has no master grid, simply clear all filters, otherwise keep the master grid related filters
      if(!master) {
        this.grid.loader.setFilter([]);
      } else {
        this.grid.loader.setFilterWithoutRefresh([]);
        if(master instanceof Array) {
          this.grid.loader.addFilters(master);
        } else {
          this.grid.loader.addFilter(master.filter_column, master.filter_value, master.filter_operator);
        }
      }
    }

    this.grid.resetActiveCell();
  }

});

WulinMaster.BehaviorManager.register("clear_filters", WulinMaster.behaviors.clearFilters);