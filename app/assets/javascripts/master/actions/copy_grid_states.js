// Copy grid states

WulinMaster.actions.CopyGridStates = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'copy_grid_states',

  handler: function() {
    var state_grid = gridManager.getGrid("state_grid_in_grid_states");
    var user_grid = gridManager.getGrid("user_in_grid_states");
    var selectedStateIds = state_grid.getSelectedIds();
    var selectedUserIds = user_grid.getSelectedIds();
    if(selectedStateIds.length == 0 || selectedUserIds.length == 0) {
      displayErrorMessage("You must select both grid states and users.");
      return false;
    } else {
      var url = "/wulin_master/grid_states/copy";
      var data = {state_ids: selectedStateIds, user_ids: selectedUserIds}
      $.post(url, data, function(response) {
        state_grid.resetActiveCell();
        user_grid.resetActiveCell();
        if(response.success) {
          state_grid.loader.reloadData();
          displayNewNotification("Grid states successfully copied to the users.");
        } else {
          displayErrorMessage(response.error_message);
        }
      });
    }
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.CopyGridStates);
