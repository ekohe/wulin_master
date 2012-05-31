// Hotkey 'C' to add record

WulinMaster.actions.HotkeyAdd = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'hotkey_add',
  event: 'keypress.add',
  triggerElementIdentifier: '.grid_container',

  handler: function(e, args) {
    if(Ui.addOrDeleteLocked()) return true;

    var grid = Ui.findCurrentGrid();
    if (grid && (e.which == 99 || e.which == 67)) {  // keypress 'C' for show dialog
      Ui.openDialog(grid.name, grid.extend_options);

      // register 'Create' button click event, need to remove to dialog action later
      $('#' + grid.name + '_submit').off("click").on('click', function() {
        Requests.createByAjax(grid, false);
        return false;
      });

      // register 'Create and Continue' button click event, need to remove to dialog action later
      $('#' + grid.name + '_submit_continue').off("click").on('click', function() {
        Requests.createByAjax(grid, true);
        return false;
      });
    }
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.HotkeyAdd);

