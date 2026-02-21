// Toolbar Item 'Create'
jQuery.event.props.push("cancel");

WulinMaster.actions.Create = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'create',

  handler: function(e) {
    var self = this;
    var grid = this.getGrid();
    var hiddenColumns = this.hidden_columns;

    if (grid.master) {
      var onceHandler = function() {
        grid.onOpenCreateModalEnd.unsubscribe(onceHandler);
        self.prepopulateMasterField(grid);
      };
      grid.onOpenCreateModalEnd.subscribe(onceHandler);
    }

    Ui.openDialog(grid, 'wulin_master_new_form', grid.options);

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
    if (!(hiddenColumns instanceof Array)) return false;

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
  },

  prepopulateMasterField: function(grid) {
    var master = grid.master;
    if (!master) return;

    var formId = grid.name + '_form';
    var $form = $('#' + formId);
    var columnName = master.filter_column;
    var masterId = master.filter_value;
    var $formTag = $form.find('form');
    var modelName = $formTag.attr('id').replace('new_', '');

    var $select = $formTag.find('select#' + modelName + '_' + columnName);
    if ($select.length > 0) {
      var attempts = 0;
      var trySetValue = function() {
        if ($select.find('option[value="' + masterId + '"]').length > 0) {
          $select.val(masterId).trigger('change');
          $select.closest('.field').find('label').addClass('active');
        } else if (attempts < 20) {
          attempts++;
          setTimeout(trySetValue, 200);
        }
      };
      trySetValue();
    } else {
      $formTag.append(
        $('<input>').attr({type: 'hidden', name: modelName + '[' + columnName + ']', value: masterId})
      );
    }
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.Create);
