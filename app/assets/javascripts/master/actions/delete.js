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
    $("#confirm_dialog").dialog({
      modal: true,
      buttons: {
        Yes: function() {
          Requests.deleteByAjax(grid, ids);
          $(this).dialog("destroy");
          // reload the master grid (for dettach detail action)
          if(self.reload_master && grid.master_grid) {
            grid.master_grid.loader.reloadData();
          }
        },
        Cancel: function() {
          $(this).dialog("destroy");
        }
      },
      close: function() {
        $(this).dialog("destroy");
      }
    });
  }
});


WulinMaster.ActionManager.register(WulinMaster.actions.Delete);