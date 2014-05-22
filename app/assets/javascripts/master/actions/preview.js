// click this button to view the specific data row in a dialog

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
        $('#' + grid.name + '_preview').remove();

        $('body').append(data);
        $scope = $('#' + grid.name + '_preview');
        $scope.dialog({
          width: 550,
          show: "blind",
          modal: true,
          buttons: {
            "Close": function() {
              $(this).dialog("destroy");
              $scope.remove();
            }
          }
        });
      });
    } else {
      displayErrorMessage("Please select one line.");
    }
  } // handler

});

WulinMaster.ActionManager.register(WulinMaster.actions.Preview);
