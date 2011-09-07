// ------------------------------ CRUD -------------------------------------
Requests = {
  // Record create along ajax
	createByAjax: function(grid, continue_on) {
		var createFormElement = $('#new_' + grid.name);
		// clear all the error messages
		createFormElement.find(".field_error").text("");
		$.ajax({
   		type:'POST',
   		url: grid.path + '.json',
   		data: createFormElement.serialize() + "&authenticity_token=" + window._token,
   		success: function(request) { 
				if (request.success == true) {
					Ui.resetForm(grid.name);
					if (!continue_on) { Ui.closeDialog(grid.name); }
					grid.store.loader.reloadData();
					// flash new create row
          // var createdIndex = Ui.findCreatedIndex(name, request.id);
          // setTimeout(function(){
          //  grid.flashCell(createdIndex, null, 300)
          // }, 500);
					
				} else {
					for(key in request.error_message){
					  var errors = "";
					  for(i in request.error_message[key]){
					    errors += (request.error_message[key][i] + " ")
					  }		  
					  createFormElement.find(".field[name=" + key + "]").find(".field_error").text(errors);
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
				if(msg.success == true) {
					grid.setSelectedRows([]);
					grid.store.loader.reloadData();
					$('.notic_flash').remove();
					var recordSize = ids.split(',').length;
					var recordUnit = recordSize > 1 ? 'records' : 'record';
					$('#indicators').before('<div class="notic_flash">' + recordSize + ' ' + recordUnit + ' has been deleted!</div>');
					$('.notic_flash').fadeOut(7000);
				} else {
					alert(msg.error_message);
				}
			}
		})
	},
	
	updateByAjax: function(grid, item) {
		delete item.slick_index;
		// format item data like time, date
		//format_data(item);
		// put ajax
		$.ajax({
			type: "POST",
			url: grid.path + "/" + item.id + ".json",
			data: decodeURIComponent($.param({_method: 'PUT', item: item, authenticity_token: window._token})),
			success: function(msg) {
				if(msg.success == true) {
    
				} else {
					alert(msg.error_message);
					grid.store.loader.reloadData();
				}
			}
		});
	},
}; // Requests