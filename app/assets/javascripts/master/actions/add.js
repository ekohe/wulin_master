// Toolbar Item 'Add'

WulinMaster.actions.Add = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'add',

  handler: function() {
    var grid = this.getGrid();
    Ui.openDialog(grid, grid.options);

    // register 'Create' button click event, need to remove to dialog action later
    $('body').off("click", '#' + grid.name + '_submit').on('click', '#' + grid.name + '_submit', function() {
      Requests.createByAjax(grid, false);
      return false;
    });
    // register 'Create and Continue' button click event, need to remove to dialog action later
    $('body').off("click", '#' + grid.name + '_submit_continue').on('click', '#' + grid.name + '_submit_continue', function() {
      Requests.createByAjax(grid, true);
      return false;
    });
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.Add);
