// ------------------------------ CRUD -------------------------------------
var Requests = {
  // Record create along ajax
	createByAjax: function(grid, continue_on) {
		var createFormElement = $('div#'+grid.name+'-form form');
		// clear all the error messages
		createFormElement.find(".field_error").text("");
		$.ajax({
   		type:'POST',
   		url: grid.path + '.json',
   		data: createFormElement.serialize() + "&authenticity_token=" + window._token,
   		success: function(request) { 		  
				if (request.success) {
					gridManager.createdIds.push(request.id);
					grid.loader.reloadData();
					if (!continue_on) { 
					  Ui.resetForm(grid.name);
            if (grid.loader.isDataLoaded()) {
					    setTimeout(function(){
    					  Ui.closeDialog(grid.name);
    					}, 100);
					  }
					}
					displayNewNotification('Record successfully created!');
				} else {
					for(key in request.error_message){
					  createFormElement.find(".field[name=" + key + "]").find(".field_error").text(request.error_message[key].join());
					}
				}
			}
 		});
	},
	
	// Delete rows along ajax 
	deleteByAjax: function(grid, ids) {
		$.ajax({
			type: 'POST',
			url: grid.path + '/' + ids + '.json',
			data: decodeURIComponent($.param({_method: 'DELETE', authenticity_token: window._token})),
			success: function(msg) {
				if(msg.success) {
					grid.setSelectedRows([]);
					grid.loader.reloadData();
				  var recordSize = $.isArray(ids) ? ids.length : ids.split(',').length;
				  var message;
				  if (recordSize > 1) {  message = recordSize+" records have been deleted."; }
				    else { message = "One record has been deleted."; }
				  displayNewNotification(message);
				} else {
					displayErrorMessage(msg.error_message);
				}
			}
		})
	},
	
	updateByAjax: function(grid, item) {
		delete item.slick_index;
		var currentRow = grid.getRowByRecordId(item.id).index;
		// format item data like time, date
		// format_data(item);
		// put ajax
		$.ajax({
			type: "POST",
			dateType: 'json',
			url: grid.path + "/" + item.id + ".json"+grid.query,
			data: decodeURIComponent($.param({_method: 'PUT', item: item, authenticity_token: window._token})),
			success: function(msg) {
				if(msg.success) {
					grid.loader.reloadData();
          // grid.loader.data[currentRow] = Ui.formatData(grid, msg["attrs"]);
          // grid.updateRow(currentRow);
				} else {
					displayErrorMessage(msg.error_message);
					grid.loader.reloadData();
				}
			}
		});
	},
	
	batchUpdateByAjax: function(grid) {
	  var ids, width, height, selectedIndexes = grid.getSelectedRows(),
    scope = $('#' + grid.name + '-form');
	  if ($.isEmptyObject(selectedIndexes)) {
	    displayErrorMessage('Please select a record');
	  } else {
	    ids = Ui.selectIds(grid);
	    if (grid.extend_options) {
        width = grid.extend_options.form_dialog_width || 600;
        height = grid.extend_options.form_dialog_height || 300;
      } else {
        width = 600;
        height = 300;
      }
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
            $('input:checkbox[data-target="' + $(e.currentTarget).attr('data-target') + '"]', scope).attr('checked', 'checked');
          });
          scope.off('change', 'input:checkbox').on('change', 'input:checkbox', function(e) {
            $('input.target_flag:checkbox[data-target="' + $(e.currentTarget).attr('data-target') + '"]', scope).attr('checked', 'checked');
          })
          
          // Empty input box when flag change to unchecked
          scope.off('change', 'input.target_flag:visible').on('change', 'input.target_flag:visible', function(){
            if ($.isEmptyObject($(this).attr('checked'))) {
              $('input[data-target="' + $(this).attr('data-target') + '"]').not(':button, :submit, :reset, :hidden, .target_flag').val('').removeAttr('checked').removeAttr('selected');
              $('select[data-target="' + $(this).attr('data-target') + '"]').val('').trigger("liszt:updated");
            }
          });
          
          // Submit the form
          $('.update_btn', scope).off('click', '**').on('click', function() {
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
              return $('input:checkbox[data-target="' + $('[name="' + v.name + '"]').attr('data-target') + '"]', scope).attr('checked') == 'checked'
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
          
          $('.btn', scope).show();
          $('.update_btn', scope).hide();
          $('.target_flag').hide();
        }
      });
	  }
	},
}; // Requests