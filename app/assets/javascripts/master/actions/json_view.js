// Toolbar Item 'JSON View'

WulinMaster.actions.JsonView = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'json_view',

  handler: function() {
    var grid = this.getGrid();
    var ids = grid.getSelectedIds();

    if (ids.length == 1) {
      var columns = grid.getColumns();
      var currentData = grid.getData()[grid.getSelectedRows()[0]];
      var jsonData;

      $.each(columns, function(index, column) {
        if (column.type == 'jsonb') {
          jsonData = JSON.parse(currentData[column.column_name]);
          return false;
        }
      });

      var $jsonViewModal = Ui.createJsonViewModal(jsonData);
      $jsonViewModal.modal('open');
    } else {
      displayErrorMessage('Please select just one record.');
    }
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.JsonView);
