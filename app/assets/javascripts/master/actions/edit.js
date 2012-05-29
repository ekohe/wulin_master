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


var batchUpdateByAjax = function(grid) {
  var ids, width, height, selectedIndexes = grid.getSelectedRows(), originTitle, newTitle,
  scope = $('#' + grid.name + '-form');
  if (!selectedIndexes || selectedIndexes.length == 0) {
    displayErrorMessage('Please select a record');
  } else {
    ids = grid.getSelectedIds();
    if (grid.extend_options) {
      width = grid.extend_options.form_dialog_width || 600;
      height = grid.extend_options.form_dialog_height || (scope.outerHeight() + 40);
    } else {
      width = 600;
      height = (scope.outerHeight() + 40);
    }
    originTitle = scope.attr('title');
    newTitle = originTitle.replace('Create new', 'Update');
    scope.attr('title', newTitle);
    scope.dialog({
      height: height,
      width: width,
      show: "blind",
      modal: true,
      create: function(event, ui) {
        Ui.setupForm(grid.name, true);
        
        // Switch to update button
        $('.btn', scope).hide();
        $('.update_btn', scope).show();
        
        // Check the checkbox when update the file
        checkTheBox(scope);
        
        // Submit the form
        submitForm(scope, grid, ids, selectedIndexes);
      },
      open: function(event, ui) {
        // Switch to update button
        $('.btn', scope).hide();
        $('.update_btn', scope).show();
        

        // Fill values
        setTimeout(function(){
          fillValues(scope, grid, selectedIndexes);
        }, 1000)
        
        // Show flag checkbox
        if (ids.length > 1) {
          $('input.target_flag', scope).show();
        } else {
          $('input.target_flag', scope).hide();
        }
      },
      close: function(event, ui) { 
        Ui.resetForm(grid.name);
        $(this).find("input:text").val("");
        $(this).find(".field_error").text("");
        $(this).dialog("destroy");  
        
        scope.attr('title', originTitle);
        $('.btn', scope).show();
        $('.update_btn', scope).hide();
        $('.target_flag').hide();
      }
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
          } else if ($.type(n[k]) === 'object' && $.type(comm[k]) === 'object' && !(comm[k]['id'] === n[k]['id'])) {
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
        $('select[data-column="' + i + '"] option[value=' + data[i]['id'] + ']').attr('selected', 'selected');
      } else if ($.type(data[i]) === 'array') {
        $.each(data[i], function(index, n) {
          $('select[data-column="' + i + '"] option[value=' + data[i][index]['id'] + ']').attr('selected', 'selected');
        })
      }
      
      inputBox.trigger("liszt:updated");
    }
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

var checkTheBox = function(scope) {
  // Check flag when change value of the box
  scope.off('keyup', 'input:text').on('keyup', 'input', function(e) {
    $('input.target_flag:checkbox[data-target="' + $(e.currentTarget).attr('data-target') + '"]', scope).attr('checked', 'checked');
  });
  scope.off('change', 'input:checkbox').on('change', 'input:checkbox:not(.target_flag)', function(e) {
    $('input.target_flag:checkbox[data-target="' + $(e.currentTarget).attr('data-target') + '"]', scope).attr('checked', 'checked');
  });
  
  // Empty input box when flag change to unchecked
  scope.off('change', 'input.target_flag:visible').on('change', 'input.target_flag:visible', function(){
    if ($.isEmptyObject($(this).attr('checked'))) {
      $('input[data-target="' + $(this).attr('data-target') + '"]').not(':button, :submit, :reset, :hidden, .target_flag').val('').removeAttr('checked').removeAttr('selected');
      $('select[data-target="' + $(this).attr('data-target') + '"]').val('').trigger("liszt:updated");
    }
  });
};

var submitForm = function(scope, grid, ids, selectedIndexes) {
  scope.off('click', '.update_btn').on('click', '.update_btn', function() {
    var originArr = $('form', scope).serializeArray(),
    checkedArr, checkedHash = {},
    objectName = $('form', scope).attr('class').replace(/new_/,'');
    
    // Collect attrs along with checked flag
    checkedArr = $.map($('input.target_flag:checked'), function(v) {
      var targetInput = $('[data-target="' + $(v).attr('data-target') + '"]').not(':button, :submit, :reset, .target_flag'),
      name = targetInput.attr('name').replace(/.*?\[/,'item[');
      return { name: name, value: (targetInput.val() || null)};
    });
    
    // Collect valid form attrbutes
    originArr = $.grep(originArr, function(v, i) {
      return $('input.target_flag:checkbox[data-target="' + $('[name="' + v.name + '"]').attr('data-target') + '"]', scope).attr('checked') == 'checked'
    });
    
    // Replace objectName to item, like user[posts][] => item[posts][]
    $.each(originArr, function(i, v) {
      if (originArr[i].name.indexOf(objectName + "[") != -1) {
        originArr[i].name = v.name.replace(/.*?\[/,'item[');
      }
    });
    
    // Merge the attrs
    checkedArr = $.extend(checkedArr, originArr);
    
    // Convert array to object
    $.each(checkedArr, function(index, n){
      checkedHash[n.name] = n.value;
    })
    
    // Update ajax request
    $.ajax({
      type: "POST",
      dateType: 'json',
      url: grid.path + "/" + ids + ".json"+grid.query,
      data: $.extend({}, {_method: 'PUT', authenticity_token: window._token}, checkedHash),
      success: function(msg) {
        if(msg.success) {
          Ui.resetForm(grid.name);
          grid.loader.reloadData();
          displayNewNotification(selectedIndexes.length + ' records been updated!');
        } else {
          displayErrorMessage(msg.error_message);
          grid.loader.reloadData();
        }
        scope.dialog("destroy"); 
      }
    });
    return false;
  });
};



WulinMaster.ActionManager.register(WulinMaster.actions.Edit);