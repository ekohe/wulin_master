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

  deleteGridRecords: function(grid, ids) {
    var self = this;
    $('#confirm_modal').modal();
    $('#confirm_modal .yes').off('click').on('click', function(){
      ids = grid.getSelectedIds();
      Requests.deleteByAjax(grid, ids);
      $('#confirm_modal').modal('hide');
      // reload the master grid (for dettach detail action)
      if(self.reload_master && grid.master_grid) {
        grid.master_grid.loader.reloadData();
      }
    })
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.Delete);