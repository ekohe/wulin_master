// Hotkey 'D' to delete record

WulinMaster.actions.HotkeyDelete = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'hotkey_delete',
  event: 'keypress.delete',
  triggerElementIdentifier: '.grid_container',

  handler: function(e, args) {
    if(Ui.addOrDeleteLocked()) return true;

    var grid = Ui.findCurrentGrid();
    if (grid && (e.which == 100 || e.which == 68)) {  // keypress 'D' for delete
      var ids = grid.getSelectedIds();
      if (ids.length > 0) {
        this.deleteGridRecords(grid, ids);
        return false;
      } else {
        displayErrorMessage("Please select a record.");
      }
    }
  }
});

// WulinMaster.ActionManager.register(WulinMaster.actions.HotkeyDelete);
