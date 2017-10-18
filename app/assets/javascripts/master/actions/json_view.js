// Toolbar Item 'JSON View'

WulinMaster.actions.JsonView = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'json_view',

  handler: function() {
    var grid = this.getGrid();
    var ids = grid.getSelectedIds();

    if (ids.length != 1) {
      displayErrorMessage('Please select a record.');
    } else {
      var jsonData = JSON.parse(grid.getData()[0]['data']);

      var $jsonViewModal = $('<div/>')
        .addClass('modal modal-fixed-footer')
        .css({overflow: 'hidden'})
        .appendTo($('body'));
      var $modalHeader = $('<div/>')
        .addClass('modal-header')
        .append($('<span/>').text('JSON Viewer'))
        .append($('<i/>').text('close').addClass('modal-close material-icons right'))
        .appendTo($jsonViewModal);
      var $modalContent = $('<div/>')
        .addClass('modal-content')
        .css({'margin': '20px 0'})
        .JSONView(jsonData)
        .appendTo($jsonViewModal);

      $jsonViewModal.modal({
        complete: function() {
          $jsonViewModal.remove();
        }
      });

      $jsonViewModal.modal('open');

    }
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.JsonView);
