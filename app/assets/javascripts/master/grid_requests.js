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
					Ui.resetForm(grid.name);
					grid.loader.reloadData();
					if (!continue_on) { Ui.closeDialog(grid.name); }
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
					alert(msg.error_message);
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
			url: grid.path + "/" + item.id + ".json",
			data: decodeURIComponent($.param({_method: 'PUT', item: item, authenticity_token: window._token})),
			success: function(msg) {
				if(msg.success) {
					grid.loader.data[currentRow] = msg["attrs"];
					grid.updateRow(currentRow);
				} else {
					alert(msg.error_message);
					grid.loader.reloadData();
				}
			}
		});
	},
}; // Requests