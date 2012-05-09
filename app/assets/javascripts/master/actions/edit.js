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
    if ($.isEmptyObject(selectedIndexes)) {
      displayErrorMessage('Please select a record');
    } else {
      ids = grid.getSelectedIds();
      if (grid.extend_options) {
        width = grid.extend_options.form_dialog_width || 600;
        height = grid.extend_options.form_dialog_height || 300;
      } else {
        width = 600;
        height = 300;
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
          
          // Show flag checkbox
          $('input.target_flag', scope).show();
          
          // Check flag when change value of the box
          scope.off('keyup', 'input:text').on('keyup', 'input', function(e) {
            $('input.target_flag:checkbox[data-target="' + $(e.currentTarget).attr('data-target') + '"]', scope).attr('checked', 'checked');
          });
          scope.off('change', 'input:checkbox').on('change', 'input:checkbox', function(e) {
            $('input.target_flag:checkbox[data-target="' + $(e.currentTarget).attr('data-target') + '"]', scope).attr('checked', 'checked');
          });
          
          // Empty input box when flag change to unchecked
          scope.off('change', 'input.target_flag:visible').on('change', 'input.target_flag:visible', function(){
            if ($.isEmptyObject($(this).attr('checked'))) {
              $('input[data-target="' + $(this).attr('data-target') + '"]').not(':button, :submit, :reset, :hidden, .target_flag').val('').removeAttr('checked').removeAttr('selected');
              $('select[data-target="' + $(this).attr('data-target') + '"]').val('').trigger("liszt:updated");
            }
          });
          
          // Submit the form
          scope.off('click', '.update_btn').on('click', '.update_btn', function() {
            var originArr = $('form', scope).serializeArray(),
            checkedArr,
            objectName = $('form', scope).attr('class').replace(/new_/,'');
            
            // Collect attrs along with checked flag
            checkedArr = $.map($('input.target_flag:visible:checked'), function(v) {
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
            
            // Update ajax request
            $.ajax({
              type: "POST",
              dateType: 'json',
              url: grid.path + "/" + ids + ".json"+grid.query,
              data: decodeURIComponent($.param({_method: 'PUT', authenticity_token: window._token}) + '&' + $.param(checkedArr)),
              success: function(msg) {
                if(msg.success) {
                  grid.setSelectedRows([]);
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
        },
        open: function(event, ui) {
          // Switch to update button
          $('.btn', scope).hide();
          $('.update_btn', scope).show();
          
          // Show flag checkbox
          $('input.target_flag', scope).show();
        },
        close: function(event, ui) { 
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
  }

  WulinMaster.ActionManager.register(WulinMaster.actions.Edit);