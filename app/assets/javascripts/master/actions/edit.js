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
  if (!selectedIndexes || selectedIndexes.length == 0) {
    displayErrorMessage('Please select a record');
  } else {
    ids = grid.getSelectedIds();
    url = grid.path + '/wulin_master_edit_form' + grid.query;
    if (version) 
      url = url + "&update_version=" + version;
    $.get(url, function(data){
      $('body').append(data);
      scope = $( '#' + name + '_form');
      
      if (grid.options) {
        width = grid.options.form_dialog_width || 600;
        height = grid.options.form_dialog_height || (scope.outerHeight() + 40);
      } else {
        width = 600;
        height = (scope.outerHeight() + 40);
      }
      scope.dialog({
        height: height,
        width: width,
        show: "blind",
        modal: true,
        create: function(event, ui) {
          Ui.setupForm(grid, true);

          // Check the checkbox when update the file
          checkTheBox(name);

          // Submit the form
          submitForm(grid, ids, selectedIndexes);
        },
        open: function(event, ui) {

          // Fill values
          setTimeout(function(){
            fillValues(scope, grid, selectedIndexes);
          }, 1000)
          
          showFlagCheckBox(scope, ids)
        },
        close: function(event, ui) {
          scope.dialog('destroy');
          scope.remove();
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
          if ($.type(n[k]) != 'object' && !(comm[k] === n[k])) {
            delete comm[k];
          } else if ($.type(n[k]) === 'object' && $.type(comm[k]) === 'object' && !compareArray(comm[k]['id'], n[k]['id'])) {
            delete comm[k];
          }
        }
      }
    })
    loadValue(scope, comm);
  }
};

var loadValue = function(scope, data) {
  for ( var i in data) {
    if ($('input:text[data-column="' + i + '"]', scope).size() > 0) {
      $('input[data-column="' + i + '"]', scope).val(data[i]);
    } else if ($('textarea[data-column="' + i + '"]', scope).size() > 0) {
      $('textarea[data-column="' + i + '"]', scope).val(data[i]);
    } else if ($('input:checkbox[data-column="' + i + '"]', scope).size() > 0) {
      if (data[i]) {
        $('input:checkbox[data-column="' + i + '"]', scope).attr('checked', 'checked');
      } else {
        $('input:checkbox[data-column="' + i + '"]', scope).removeAttr('checked');
      }
    } else if ($('select[data-column="' + i + '"]', scope).size() > 0) {
      inputBox = $('select[data-column="' + i + '"]', scope);
      inputBox.find('option').removeAttr('selected');
      if ($.type(data[i]) === 'string') {
        $('option[value="' + data[i] + '"]', inputBox).attr('selected', 'selected');
      } else if ($.type(data[i]) === 'object') {
        if ($.type(data[i]['id']) === 'array') {
          $.each(data[i]['id'],function(_i, _v){
            $('option[value=' + _v + ']', inputBox).attr('selected', 'selected');
          })
        } else {
          $('option[value=' + data[i]['id'] + ']', inputBox).attr('selected', 'selected');
        }
      } else if ($.type(data[i]) === 'array') {
        $.each(data[i], function(index, n) {
          $('option[value=' + data[i][index]['id'] + ']', inputBox).attr('selected', 'selected');
        })
      }
      
      //inputBox.trigger("liszt:updated");
      if (inputBox.hasClass("chzn-done")) {
        inputBox.trigger("liszt:updated");
      } else {
        inputBox.chosen();
        // inputBox.chosen({allow_single_deselect: true});
      }

      distinctInput(inputBox);

    }
  }
};

var distinctInput = function(inputBox) {
  var addNewSelect;
  // This is a crazy feature
  if ($('#' + inputBox.attr('id') + '_chzn li:contains("Add new Option")').size() > 0) {
    addNewSelect = $('#' + inputBox.attr('id'));
    $('#' + addNewSelect.attr('id') + '_chzn li:contains("Add new Option")').off('mouseup').on('mouseup', function(event) {
      var $select = addNewSelect;
      var $dialog = $("<div/>").attr({id: 'distinct_dialog', title: "Add new option", class: "create_form"}).css('display', 'none').appendTo($('body'));
      var $fieldDiv = $("<div />").attr({style: 'padding: 20px 30px;'});
      var $submitDiv = $("<div />").attr({style: 'padding: 0 30px;'});
      $fieldDiv.append('<label for="distinct_field" style="display: inline-block; margin-right: 6px;">New Option</label>');
      $fieldDiv.append('<input id="distinct_field" type="text" style="width: 250px" size="30" name="distinct_field">');
      $fieldDiv.appendTo($dialog);
      $submitDiv.append('<input id="distinct_submit" class="btn success" type="submit" value=" Add Option " name="commit">');
      $submitDiv.appendTo($dialog);
      $dialog.dialog({
        autoOpen: true,
        width: 450,
        height: 180,
        modal: true,
        buttons: {
          "Cancel": function() {
            $(this).dialog("destroy");
            $(this).remove();
          }
        },
        open: function(event, ui) {
          $('#distinct_submit', $(this)).on('click', function(){
              var optionText = $('#distinct_dialog #distinct_field').val();
              if (optionText) {
                  $('option:contains("Add new Option")', $select).before('<option value="' + optionText + '">' + optionText + '</option>');
                  $select.val(optionText);
                  $('input.target_flag:checkbox[data-target="' + $select.attr('data-target') + '"]').attr('checked', 'checked');
                  $select.trigger('liszt:updated');
                  $dialog.dialog("destroy");
                  $dialog.remove();
              } else {
                  alert('New option can not be blank!')
              }
          })
        },
        close: function(event, ui) {
          $(this).dialog("destroy");
          $(this).remove();
        }
      });

      return false;
    });
  }
}

var showFlagCheckBox = function(scope, ids) {
  if (ids.length > 1) {
    // Show flag checkbox
    $('input.target_flag', scope).show();
  } else {
    $('input.target_flag:visible', scope).hide();
  }
};

var checkTheBox = function(name) {
  var scope = $( '#' + name + '_form');
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
  scope.off('change', 'input.target_flag:visible').on('change', 'input.target_flag:visible', function(){
    if ($.isEmptyObject($(this).attr('checked'))) {
      $('input[data-target="' + $(this).attr('data-target') + '"]').not(':button, :submit, :reset, :hidden, .target_flag').val('').removeAttr('checked').removeAttr('selected');
      $('select[data-target="' + $(this).attr('data-target') + '"]').val('').trigger("liszt:updated");
    }
  });
};

var grepValues = function(formData, jqForm, options) {
  var flagDom;
  for(var i = formData.length - 1; i >= 0; i--) {
    flagDom = $('input.target_flag:checkbox[data-target="' + $('[name="' + formData[i].name + '"]').not('[type="hidden"]').attr('data-target') + '"]', scope);
    if(flagDom.not(':checked').size() > 0) {
      formData.splice(i, 1);
    }
  }
};

var submitForm = function(grid, ids, selectedIndexes) {
  var name = grid.name, 
  $scope = $( '#' + name + '_form'),
  $form = $('form', $scope);
  $scope.off('click', '.update_btn').on('click', '.update_btn', function() {
    var options = {
      dateType: 'json',
      url: grid.path + "/" + ids + ".json"+grid.query,
      data: {_method: 'PUT'},
      beforeSubmit: grepValues,
      success: function(msg) {
        if(msg.success) {
          Ui.resetForm(grid.name);
          
          grid.loader.reloadData();
          displayNewNotification(selectedIndexes.length + ' records been updated!');
        } else {
          displayErrorMessage(msg.error_message);
          grid.loader.reloadData();
        }
        $scope.dialog("destroy"); 
        $scope.remove();
      }
    }
    $form.ajaxSubmit(options);
    return false;
  });
};

var compareArray = function(x, y) {
  if ($.type(x) == 'array' && $.type(y) == 'array') {
    if (x.length != y.length) {
      return false;
    }

    for (key in x) {
      if (x[key] != y[key]) {//!== So that the the values are not converted while comparison
        return false;
      }
    }
    return true
  } else {
    return x === y
  }
};



WulinMaster.ActionManager.register(WulinMaster.actions.Edit);