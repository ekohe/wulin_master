// Toolbar Item 'Add'
jQuery.event.props.push("cancel");

WulinMaster.actions.Add = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'add',

  handler: function(e) {
    var self = this;
    var grid = this.getGrid();
    var hiddenColumns = this.hidden_columns;

    Ui.openModal(grid, 'wulin_master_new_form', grid.options);

    // register 'Create' button click event, need to remove to dialog action later
    $('body').off("click", '#' + grid.name + '_submit').on('click', '#' + grid.name + '_submit', function(evt) {
      if(hiddenColumns) self.fillHiddenColumns(grid, hiddenColumns);

      var e = jQuery.Event('beforesubmit.wulin', {target: this});

      var _cancel = false;
      cancel = function() { _cancel = true; }

      $(this).parents('form').trigger(e, cancel);

      if(_cancel) {
        return false;
      }

      Requests.createByAjax(grid, false);
      return false;
    });
    // register 'Create and Continue' button click event, need to remove to dialog action later
    $('body').off("click", '#' + grid.name + '_submit_continue').on('click', '#' + grid.name + '_submit_continue', function(evt) {
      if(hiddenColumns) self.fillHiddenColumns(grid, hiddenColumns);

      var e = jQuery.Event('beforesubmit.wulin', {target: this});

      var _cancel = false;
      cancel = function() { _cancel = true; }

      $(this).parents('form').trigger(e, cancel);

      if(_cancel) {
        return false;
      }

      Requests.createByAjax(grid, true);
      return false;
    });
  },

  fillHiddenColumns: function(grid, hiddenColumns) {
    var self = this;
    if(!hiddenColumns instanceof Array) return false;

    var currentFilters = grid.loader.getFilters();
    $.each(currentFilters, function(index, filter) {
      if(hiddenColumns.indexOf(filter[0]) != -1) {
        self.addHiddenColumn(filter[0], filter[1]);
      }
    });
  },

  addHiddenColumn: function(column, value) {
    var $createForm = $(".create_form form");
    var model = $createForm.attr("id").replace("new_", "");
    $('<input/>').attr("id", model + "_" + column).attr("type", "hidden").attr("value", value).attr("name", model + '[' + column + ']').appendTo($createForm);
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.Add);
