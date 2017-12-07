// Show all records

WulinMaster.actions.ShowAll = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'show_all',

  handler: function() {
    var grid = this.getGrid();
    this.grid.loader.setFilter([]);
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.ShowAll);
