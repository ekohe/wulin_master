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
          $('.target_flag').remove();
          $('label', scope).each(function(){
            $(this).after($('<input />').attr({type: 'checkbox', class: 'target_flag', 'date-target': $('#' + $(this).attr('for')).attr('name') }));
          });
          $('input', scope).on('change', function() {
            $('input:checkbox[date-target="' + $(this).attr('name') + '"]', scope).attr('checked', 'checked');
          });
          
          $('.btn', scope).hide();
          $('.submit', scope).prepend($('<input />').addClass('btn success update_btn').attr({value: ' Update ', type: 'submit', name: 'commit'}));
          
          $('.update_btn', scope).off('click', '**').on('click', function() {
    				var originArr = $('form', scope).serializeArray(), newHash = {};
    				// Collect valid form attrbutes
            $.each(originArr, function(i, v) {
              if (!$.isEmptyObject(v.value) && $('input:checkbox[date-target="' + v.name + '"]', scope).attr('checked') == 'checked') {
                var attrName = v.name.replace(/.*?\[/, '').replace(/\].*?/, '');
                newHash[attrName] = v.value;
              }
            });
            $.ajax({
              type: "POST",
              dateType: 'json',
              url: grid.path + "/" + ids + ".json"+grid.query,
              data: decodeURIComponent($.param({_method: 'PUT', item: newHash, authenticity_token: window._token})),
              success: function(msg) {
                if(msg.success) {
                  grid.setSelectedRows([]);
                  grid.loader.reloadData();
                  displayNewNotification(selectedIndexes.length + ' records been updated!');
                } else {
                  displayErrorMessage(msg.error_message);
                  grid.loader.reloadData();
                }
                $('.update_btn', scope).remove();
                scope.dialog("destroy"); 
              }
            });
    			  return false;
    			});
  			},
        close: function(event, ui) { 
          $(this).find("input:text").val("");
          $(this).find(".field_error").text("");
          $(this).dialog("destroy");  
          $('.btn', scope).show();
          $('.update_btn', scope).remove();
          $('.target_flag').remove();
        }
      });
	  }
	},
}; // Requests