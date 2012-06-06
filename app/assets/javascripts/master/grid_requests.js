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
	updateByAjax: function(grid, item) {
		delete item.slick_index;
		var currentRow = grid.getRowByRecordId(item.id).index;
		$.ajax({
			type: "POST",
			dateType: 'json',
			url: grid.path + "/" + item.id + ".json"+grid.query,
			data: decodeURIComponent($.param({_method: 'PUT', item: item, authenticity_token: window._token})),
			success: function(msg) {
				if(msg.success) {
					grid.loader.reloadData();
				} else {
					displayErrorMessage(msg.error_message);
					grid.loader.reloadData();
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
		});
	}
}; // Requests