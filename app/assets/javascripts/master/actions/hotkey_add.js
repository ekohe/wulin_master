// Hotkey 'C' to add record

WulinMaster.actions.HotkeyAdd = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'hotkey_add',
  event: 'keypress.add',
  triggerElementIdentifier: '.grid_container',

  handler: function(e, args) {
    if(Ui.addOrDeleteLocked()) return true;

    var grid = Ui.findCurrentGrid();
    if (grid && (e.which == 99 || e.which == 67)) {  // keypress 'C' for show modal
      Ui.openModal(grid, 'wulin_master_new_form', grid.options);

      // register 'Create' button click event
      $('body').off("click", '#' + grid.name + '_submit').on('click', '#' + grid.name + '_submit', function() {
        Requests.createByAjax(grid, false);
        return false;
      });

      // register 'Create and Continue' button click event
      $('body').off("click", '#' + grid.name + '_submit_continue').on('click', '#' + grid.name + '_submit_continue', function() {
        Requests.createByAjax(grid, true);
        return false;
      });
    }
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.HotkeyAdd);

