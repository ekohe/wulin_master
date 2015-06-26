// click this button to view the specific data row in a modal

WulinMaster.actions.Preview = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'preview',

  handler: function() {
    var grid = this.getGrid();
    var selectedData = grid.loader.data[grid.getSelectedRows()[0]];
    var url;
    if (selectedData) {
      url = grid.path + '/wulin_master_preview/?id=' + selectedData.id;
      $.get(url, function(data) {
        var $scope;
        var grid_name = grid.name.split("_")[0];
        $('#' + grid_name + '_preview').remove();

        displayGridMessage(null, null, null, 'Ok', data, 'Preview');
      });
    } else {
      displayErrorMessage("Please select one line.");
    }
  } // handler

});

WulinMaster.ActionManager.register(WulinMaster.actions.Preview);