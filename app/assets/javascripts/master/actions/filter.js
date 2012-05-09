// Toolbar Item: Filter

WulinMaster.actions.Filter = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'filter',

  // filter button click handler is already defined in Slick.FilterPanel, so here we override the activate function to avoid call handler again
  activate: function(){
    var grid = this.getGrid();
    var filterPanel = new Slick.FilterPanel(grid, grid.loader, this.triggerElement, grid.states["filter"]);
    grid.filterPanel = filterPanel;
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.Filter);