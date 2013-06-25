// Detail grid Toolbar Item 'Add'
jQuery.event.props.push("cancel");

WulinMaster.actions.DetailAdd = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'detail_add',

  handler: function(e) {
    var grid = this.getGrid();
    this.grid = grid;
    var self = this;

    Ui.openDialog(grid, 'wulin_master_new_form', grid.options, function() {setTimeout(function(){
      self.assignMaster(grid);
    }, 1000);});

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
  },

  assignMaster: function(){
    // TODO
    // 1. find the master grid and the selected record in master grid
    // 2. in the create dialog, find the master id dropdown
    // 3. set the dropdown value as the selected record in master grid, and disable it
    console.log("start")
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.DetailAdd);
