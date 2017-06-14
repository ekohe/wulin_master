// Toolbar Item: Filter
// TODO: Filter feature is bound to grid and not triggered by action.
//       this action is not in use and should be removed.

WulinMaster.actions.Filter = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'filter',

  // filter button click handler is already defined in FilterPanel, so here we override the activate function to avoid call handler again
  activate: function(){
    var grid = this.getGrid();
    // var filterPanel = new WulinMaster.FilterPanel(grid, grid.loader, this.triggerElement, grid.states["filter"]);
    var filterPanel = new WulinMaster.FilterPanel(grid, grid.loader, grid.states["filter"]);
    grid.filterPanel = filterPanel;
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.Filter);
