// Toolbar Item 'Delete'

WulinMaster.actions.Delete = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'delete',

  handler: function() {
    var grid = this.getGrid();

    var ids = grid.getSelectedIds();
    if (ids.length > 0) {
      this.deleteGridRecords(grid, ids);
      return false;
    } else {
      displayErrorMessage("Please select a record.");
    }
  }
});


WulinMaster.ActionManager.register(WulinMaster.actions.Delete);
