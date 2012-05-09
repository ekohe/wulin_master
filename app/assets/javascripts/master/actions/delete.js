// Toolbar Item 'Delete'

WulinMaster.actions.Delete = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'delete',

  handler: function() {
    var grid = this.getGrid();

    var ids = grid.getSelectedIds();
    if (ids.length > 0) {
      deleteGridRecords(grid, ids);
      return false;
    } else {
      displayErrorMessage("Please select a record.");
    }
  }
});

// Handle delete confirm with dialog
var deleteGridRecords = function(grid, ids) {
  $("#confirm_dialog").dialog({
    modal: true,
    buttons: {
      Yes: function() {
        Requests.deleteByAjax(grid, ids);
        $(this).dialog("destroy");
      },
      Cancel: function() {
        $(this).dialog("destroy");
      }
    },
    close: function() { 
      $(this).dialog("destroy");
    }
  });
};

WulinMaster.ActionManager.register(WulinMaster.actions.Delete);