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
  var ids, name, scope, width, height, selectedIndexes, url;
  selectedIndexes = grid.getSelectedRows();
  name = grid.name;
  scope = $( '#' + name + '_form');

  if (!selectedIndexes || selectedIndexes.length === 0) {
    displayErrorMessage('Please select a record');
  } else {
    ids = grid.getSelectedIds();
    if (ids.length > 350) {
      displayErrorMessage('You select too many rows, please select less than 350 rows.');
      return;
    }
    url = grid.path + '/wulin_master_edit_form' + grid.query + '&ids=' + ids;
    if (version)
      url = url + "&update_version=" + version;
    $.get(url, function(data){
      Ui.createModelModal(grid, data, {
        ready: function(modal, trigger) {
          Ui.setupForm(grid, true, selectedIndexes);
          Ui.setupComponents(grid);
          showFlagCheckBox(modal, ids);
          checkTheBox(name);
          submitForm(grid, ids, selectedIndexes);
          setTimeout( function() { $(document).trigger('FormLoaded') }, 320);
        }
      });
    });
  }
};

var fillValues = function(scope, grid, selectedIndexes) {
  var data, inputBox, dataArr, comm = {};
  if (selectedIndexes.length == 1) {
    data = grid.loader.data[selectedIndexes[0]];
    loadValue(scope, data);
  } else {
    dataArr = $.map(selectedIndexes, function(n, i){
      return grid.loader.data[n];
    });
    $.each(dataArr, function(index, n){
      for (var k in n) {
        if (index === 0) {
          if (k != 'id' && k != 'slick_index') comm[k] = n[k];
        } else {
          if ($.type(n[k]) != 'object' && comm[k] !== n[k]) {
            delete comm[k];
          } else if ($.type(n[k]) === 'object' && $.type(comm[k]) === 'object' && !compareArray(comm[k]['id'], n[k]['id'])) {
            delete comm[k];
          }
        }
      }
    });
    loadValue(scope, comm);
  }

  // Avoid label overlapping input to MD textfield
  $('#' + grid.name + '_form .field').filter(function () {
    return !!$(this).find('input').val();
  }).find('label').addClass('active');
};

var loadValue = function(scope, data) {
  for ( var i in data) {
    if ($('input:text[data-field="' + i + '"]', scope).size() > 0) {
      $('input[data-field="' + i + '"]', scope).val(data[i]);
    } else if ($('textarea[data-field="' + i + '"]', scope).size() > 0) {
      $('textarea[data-field="' + i + '"]', scope).val(data[i]);
    } else if ($('input:checkbox[data-field="' + i + '"]', scope).size() > 0) {
      if (data[i]) {
        $('input:checkbox[data-field="' + i + '"]', scope).prop('checked', true);
      } else {
        // data only include visible columns, some formable columns' value are not included in data.
        // we should not unchecked an checked checkbox, only because it's not visible column.
        // $('input:checkbox[data-field="' + i + '"]', scope).removeAttr('checked');
      }
    } else if ($('select[data-field="' + i + '"]', scope).size() > 0) {
      inputBox = $('select[data-field="' + i + '"]', scope);
      if ($.type(data[i]) === 'string') {
        inputBox.val(data[i]);
      } else if ($.type(data[i]) === 'object') {
        if ($.type(data[i]['id']) === 'array') {
          inputBox.val(data[i]['id']);
        } else {
          inputBox.val(data[i]['id']);
        }
      } else if ($.type(data[i]) === 'array') {
        inputBox.val(data[i]);
      }
    }
  }
};

var showFlagCheckBox = function(scope, ids) {
  if (ids.length > 1) {
    $('.target_flag_container', scope).show();
  } else {
    $('.target_flag_container', scope).hide();
  }
};

var checkTheBox = function(name) {
  var scope = $( '#' + name + '_form');
  // Check flag when change value of the box
  scope.off('keyup', 'input:text, input:password, textarea').on('keyup', 'input:text, input:password, textarea', function(e) {
    $('input.target_flag:checkbox[data-target="' + $(e.currentTarget).attr('data-target') + '"]').prop('checked', true);
  });
  scope.off('change', 'input:checkbox, input:file').on('change', 'input:checkbox:not(.target_flag), input:file', function(e) {
    $('input.target_flag:checkbox[data-target="' + $(e.currentTarget).attr('data-target') + '"]').prop('checked', true);
  });

  // Date picker \ datetime picker \ time picker
  scope.off('change', 'input.flatpickr-input').on('change', 'input.flatpickr-input', function(e) {
    $('input.target_flag:checkbox[data-target="' + $(e.currentTarget).attr('data-target') + '"]').prop('checked', true);
  });

  // Empty input box when flag change to unchecked
  scope.off('change', 'input.target_flag:visible').on('change', 'input.target_flag:visible', function(){
    if ($(this).prop('checked') == false) {
      $('input[data-target="' + $(this).attr('data-target') + '"]').not(':button, :submit, :reset, :hidden, .target_flag').val('').removeAttr('checked').removeAttr('selected');
      $('select[data-target="' + $(this).attr('data-target') + '"]').val('').trigger("chosen:updated");
    }
  });
};

var grepValues = function(formData, jqForm, options) {
  var flagDom;
  for(var i = formData.length - 1; i >= 0; i--) {
    flagDom = $('input.target_flag:checkbox[data-target="' + $('[name="' + formData[i].name + '"]').not('[type="hidden"]').attr('data-target') + '"]', jqForm);
    if(flagDom.not(':checked').size() > 0) {
      formData.splice(i, 1);
    }
  }
};

var submitForm = function(grid, ids, selectedIndexes) {
  var name = grid.name,
  $scope = $( '#' + name + '_form'),
  $form = $('form', $scope);
  var submitButton = $form.find("input[type='submit']");
  $scope.off('click', '.update_btn').on('click', '.update_btn', function() {
    var options = {
      dateType: 'json',
      url: grid.path + "/" + ids + ".json"+grid.query,
      data: {_method: 'PUT'},
      beforeSubmit: grepValues,
      beforeSend: function() {
        submitButton.prop('disabled', 'disabled');
      },
      success: function(msg) {
        if(msg.success) {
          Ui.resetForm(grid.name);
          grid.loader.reloadData();
          if (grid.reloadMasterAfterUpdates && grid.master_grid) {
            grid.master_grid.loader.reloadData();
          }
          if (selectedIndexes.length > 1) {
            displayNewNotification(selectedIndexes.length + ' ' + grid.model.toLowerCase() + 's updated');
          } else {
            displayNewNotification('1 ' + grid.model.toLowerCase() + ' updated');
          }

        } else {
          displayErrorMessage(msg.error_message);
          saveMessage('Error updating ' + grid.model.toLowerCase(), 'error');
          grid.loader.reloadData();
        }
        $scope.closest('.modal').modal('close');
      },
      complete: function() {
        submitButton.prop('disabled', null);
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
      if (x[k] != y[k]) {//!== So that the the values are not converted while comparison
        return false;
      }
    }
    return true;
  } else {
    return x === y;
  }
};

WulinMaster.ActionManager.register(WulinMaster.actions.Edit);
