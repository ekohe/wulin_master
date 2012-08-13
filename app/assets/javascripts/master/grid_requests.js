// ------------------------------ CRUD -------------------------------------
var Requests = {
	// Record create by ajax
	createByAjax: function(grid, continue_on) {
	  var createFormElement = $('div#'+grid.name+'_form form');
	  // clear all the error messages
	  createFormElement.find(".field_error").text("");
	  $.ajax({
	    type:'POST',
	    url: grid.path + '.json',
	    data: createFormElement.serialize() + "&authenticity_token=" + window._token,
	    success: function(request) {      
	      if (request.success) {
	      	grid.resetActiveCell();
	        grid.operatedIds = [request.id];
	        grid.loader.reloadData();
	        if (continue_on) {
	          Ui.refreshCreateForm(grid);
	        } else {
	          if (grid.loader.isDataLoaded()) {
	            setTimeout(function(){ Ui.closeDialog(grid.name); }, 100);
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

	// Record update by ajax
	updateByAjax: function(grid, item, editCommand) {
		delete item.slick_index;
		var ids = item.id.toString();
		var currentRow;
		// multiple records
		if (ids.indexOf(',') != -1) {
			ids = ids.split(',');
			currentRow = grid.getRowByRecordId(ids[ids.length-1]).index;
		} else {	// one record
			currentRow = grid.getRowByRecordId(ids).index;
		}
		$.ajax({
			type: "POST",
			dateType: 'json',
			url: grid.path + "/" + item.id + ".json"+grid.query,
			data: decodeURIComponent($.param({_method: 'PUT', item: item, authenticity_token: window._token})),
			success: function(msg) {
				if(msg.success) {
					var from = parseInt(currentRow / 200) * 200;
					grid.loader.reloadData(from, currentRow);
				} else {
					displayErrorMessage(msg.error_message);
					if(editCommand) {
						editCommand.undo();
					} else {
						grid.loader.reloadData();
					}
				}
			}
		});
	},

	// Delete rows along ajax 
	deleteByAjax: function(grid, ids, force) {
		if(force == undefined) force = false;
		$.ajax({
			type: 'POST',
			url: grid.path + '/' + ids + '.json?screen=' + grid.screen + '&force=' + force,
			data: decodeURIComponent($.param({_method: 'DELETE', authenticity_token: window._token})),
			success: function(msg) {
				if(msg.success) {
					grid.resetActiveCell();
					grid.loader.reloadData();
				  var recordSize = $.isArray(ids) ? ids.length : ids.split(',').length;
				  var message;
				  if (recordSize > 1) { 
				  	message = recordSize+" records have been deleted."; 
				  } else { 
				  	message = "One record has been deleted."; 
				  }
				  displayNewNotification(message);
				} else if(msg.confirm) {
					$("#confirm_dialog").dialog({
            modal: true,
            open: function() {
            	if(msg.warning_message) $(this).find('#confirm_content').text(msg.warning_message);
            },
            buttons: {
              Confirm: function() {
                Requests.deleteByAjax(grid, ids, true);
                $(this).find('#confirm_content').text("Are you sure to do this ?");
                $(this).dialog("destroy");
              },
              Cancel: function() {
              	$(this).find('#confirm_content').text("Are you sure to do this ?");
                $(this).dialog("destroy");
              }
            },
            close: function() { 
            	$(this).find('#confirm_content').text("Are you sure to do this ?");
              $(this).dialog("destroy");
            }
          });
				} else {
					displayErrorMessage(msg.error_message);
				}
			}
		});
	}
}; // Requests