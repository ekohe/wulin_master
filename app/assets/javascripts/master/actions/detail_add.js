// Detail grid Toolbar Item 'Add'
// jQuery.event.props.push("cancel");

WulinMaster.actions.DetailAdd = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'detail_add',

  handler: function(e) {
    var grid = this.getGrid();
    var self = this;

    Ui.openDialog(grid, 'wulin_master_new_form', grid.options, function() {setTimeout(function(){
      self.assignMaster(grid);
    }, 100);});

    // register 'Create' button click event, need to remove to dialog action later
    $('body').off("click", '#' + grid.name + '_submit').on('click', '#' + grid.name + '_submit', function() {
      $("#post_blogger_id").removeAttr("disabled");
      Requests.createByAjax(grid, false);
      return false;
    });
    // register 'Create and Continue' button click event, need to remove to dialog action later
    $('body').off("click", '#' + grid.name + '_submit_continue').on('click', '#' + grid.name + '_submit_continue', function() {
      $("#post_blogger_id").removeAttr("disabled");
      Requests.createByAjax(grid, true);
      return false;
    });
  },

  assignMaster: function(grid){
    // TODO
    // 1. find the master grid and the selected record in master grid
    // 2. in the create dialog, find the master id dropdown
    // 3. set the dropdown value as the selected record in master grid, and disable it
    var master_model_id = grid.master.filter_value;
    $("#post_blogger_id").attr("disabled", "disabled");
    $("#post_blogger_id").attr("value", master_model_id).trigger('liszt:updated');
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.DetailAdd);
