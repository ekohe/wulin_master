// Detail grid Toolbar Item 'Add'

WulinMaster.actions.DetailCreate = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'detail_create',

  handler: function(e) {
    var self = this;
    var grid = this.getGrid();
    var grid_parent_id = grid.model.toLowerCase() + "_" + grid.master.filter_column;

    Ui.openDialog(grid, 'wulin_master_new_form', grid.options, function() {setTimeout(function(){
      self.assignMaster(grid, grid_parent_id);
    }, 100);});

    // register 'Create' button click event, need to remove to dialog action later
    $('body').off("click", '#' + grid.name + '_submit').on('click', '#' + grid.name + '_submit', function() {
      $("#" + grid_parent_id).removeAttr("disabled");
      Requests.createByAjax(grid, false);
      return false;
    });
    // register 'Create and Continue' button click event, need to remove to dialog action later
    $('body').off("click", '#' + grid.name + '_submit_continue').on('click', '#' + grid.name + '_submit_continue', function() {
      $("#" + grid_parent_id).removeAttr("disabled");
      Requests.createByAjax(grid, true);
      return false;
    });
  },

  assignMaster: function(grid, grid_parent_id){
    var master_model_id = grid.master.filter_value;
    $("#" + grid_parent_id).attr("disabled", "disabled");
    $("#" + grid_parent_id).attr("value", master_model_id).trigger('liszt:updated');
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.DetailCreate);
