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
  },

  // Handle delete confirm with dialog
  deleteGridRecords: function(grid, ids) {
    var self = this;
    $('#confirm-modal').modal('open');
    $('#confirmed-btn').on('click', function() {
      Requests.deleteByAjax(grid, ids);
      $('#confirm-modal').modal('close');
      // reload the master grid (for dettach detail action)
      if(self.reload_master && grid.master_grid) {
        grid.master_grid.loader.reloadData();
      }
    })
  }
});


WulinMaster.ActionManager.register(WulinMaster.actions.Delete);
