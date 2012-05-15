// ------------------------------ CRUD -------------------------------------
var Requests = {	
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
	}
}; // Requests