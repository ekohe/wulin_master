WulinMaster.actions.DynamicEdit = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'dynamic_edit',
  triggerElementIdentifier: '.dynamic_toolbar',

  handler: function(e, args) {
    var grid = this.getGrid();
    var version = $(e.currentTarget).data('version');

    // Batch update action
    batchUpdateByAjax(grid, version);
    return false;
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.DynamicEdit);