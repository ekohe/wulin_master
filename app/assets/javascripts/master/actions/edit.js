// Toolbar Item: 'Edit'

WulinMaster.actions.Edit = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'edit',

  handler: function() {
    var grid = this.getGrid();

    // Batch update action
    batchUpdateByAjax(grid);
    return false;
  }
});

var batchUpdateByAjax = function(grid, version) {
  var ids, name, width, height, selectedIndexes, url;
  selectedIndexes = grid.getSelectedRows();
  name = grid.name;
  if (!selectedIndexes || selectedIndexes.length === 0) {
    displayErrorMessage('Please select a record');
  } else {
    ids = grid.getSelectedIds();
    if (ids.length > 350) {
      displayErrorMessage('You select too many rows, please select less than 350 rows.');
      return;
    }
    url = grid.path + '/wulin_master_edit_form' + grid.query;
    if (version)
      url = url + "&update_version=" + version;
    $.get(url, function(data) {
      $('#' + name + '_form').remove();
      $('body').append(data);
      scope = $('#' + name + '_form');

      if (grid.options) {
        width = grid.options.form_dialog_width || 600;
        height = grid.options.form_dialog_height || (scope.outerHeight() + 40);
      } else {
        width = 600;
        height = (scope.outerHeight() + 40);
      }
      $("#" + name + "_form").modal();
      $("#" + name + "_form").on('shown.bs.modal', function(e) {
        showFlagCheckBox(scope, ids);

        Ui.setupForm(grid, true, selectedIndexes);

        // Check the checkbox when update the file
        checkTheBox(name);

        // Submit the form
        submitForm(grid, ids, selectedIndexes);
      });
    });
  }
};

var showFlagCheckBox = function(scope, ids) {
  if (ids.length > 1) {
    // Show flag checkbox
    $('input.target_flag', scope).show();
  } else {
    $('input.target_flag:visible', scope).hide();
  }
};

var checkTheBox = function(name) {
  var scope = $('#' + name + '_form');
  // Check flag when change value of the box
  scope.off('keyup', 'input:text, input:password, textarea').on('keyup', 'input:text, input:password, textarea', function(e) {
    $('input.target_flag:checkbox[data-target="' + $(e.currentTarget).attr('data-target') + '"]').attr('checked', 'checked');
  });
  scope.off('change', 'input:checkbox, input:file').on('change', 'input:checkbox:not(.target_flag), input:file', function(e) {
    $('input.target_flag:checkbox[data-target="' + $(e.currentTarget).attr('data-target') + '"]').attr('checked', 'checked');
  });

  // Date picker \ datetime picker \ time picker
  scope.off('change', 'input.hasDatepicker').on('change', 'input.hasDatepicker', function(e) {
    $('input.target_flag:checkbox[data-target="' + $(e.currentTarget).attr('data-target') + '"]').attr('checked', 'checked');
  });

  // Empty input box when flag change to unchecked
  scope.off('change', 'input.target_flag:visible').on('change', 'input.target_flag:visible', function() {
    if ($.isEmptyObject($(this).attr('checked'))) {
      $('input[data-target="' + $(this).attr('data-target') + '"]').not(':button, :submit, :reset, :hidden, .target_flag').val('').removeAttr('checked').removeAttr('selected');
      $('select[data-target="' + $(this).attr('data-target') + '"]').val('').trigger("liszt:updated");
    }
  });
};

var grepValues = function(formData, jqForm, options) {
  var flagDom;
  for (var i = formData.length - 1; i >= 0; i--) {
    flagDom = $('input.target_flag:checkbox[data-target="' + $('[name="' + formData[i].name + '"]').not('[type="hidden"]').attr('data-target') + '"]', scope);
    if (flagDom.not(':checked').size() > 0) {
      formData.splice(i, 1);
    }
  }
};

var submitForm = function(grid, ids, selectedIndexes) {
  var name = grid.name,
    $scope = $('#' + name + '_form'),
    $form = $('form', $scope);
  $scope.off('click', '.update_btn').on('click', '.update_btn', function() {
    var options = {
      dateType: 'json',
      url: grid.path + "/" + ids + ".json" + grid.query,
      data: {
        _method: 'PUT'
      },
      beforeSubmit: grepValues,
      success: function(msg) {
        if (msg.success) {
          Ui.resetForm(grid.name);

          grid.loader.reloadData();
          if (selectedIndexes.length > 1) {
            displayNewNotification(selectedIndexes.length + ' records updated!');
          } else {
            displayNewNotification('1 record updated!');
          }

        } else {
          displayErrorMessage(msg.error_message);
          grid.loader.reloadData();
        }
        $("#" + grid.name + "_form").modal('hide');
      }
    };
    $form.ajaxSubmit(options);
    return false;
  });
};

var compareArray = function(x, y) {
  if ($.type(x) == 'array' && $.type(y) == 'array') {
    if (x.length != y.length) {
      return false;
    }

    for (var k in x) {
      if (x[k] != y[k]) { //!== So that the the values are not converted while comparison
        return false;
      }
    }
    return true;
  } else {
    return x === y;
  }
};

WulinMaster.ActionManager.register(WulinMaster.actions.Edit);
