// Toolbar Item 'Add Detail' for detail grid

WulinMaster.actions.AddDetail = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'add_detail',

  handler: function(e) {
    var self = this;
    var masterId = this.target.master.filter_value;

    var modalId = '#grid_modal';

    var openCallback = function() {
      self.getModelGrid(masterId, modalId);
    };

    var confirmCallback = function(){
      self.appendNewRecordToMiddleTable(masterId, modalId);
    };

    var title = 'Attach';

    displayGridMessage(openCallback, confirmCallback, 'Cancel', 'Attach', null, title);
  },

  getModelGrid: function(masterId, modalId) {
    var master = $.extend({}, this.target.master);
    var screen = this.screen;
    // first get controller of the detail model, then open the modal fill the detail grid
    $.get('/wulin_master/get_detail_controller?model=' + this.model + '&middle_model=' + this.target.model, function(data){
      var url = "/" + data.controller + "?screen=" + screen + "&filters[][column]=" + master.filter_column + "&filters[][value]=" + masterId + "&filters[][operator]=exclude";
      $.ajax({
        type: 'GET',
        url: url
      })
      .success(function(response){
        $modal = $(modalId);
        $modal.find('.modal-body').html(response);
        // copy the target's master to detail grid, just replace the operator to 'exclude'
        var gridName = $modal.find(".grid_container").attr("name");
        var grid = gridManager.getGrid(gridName);
        master["filter_operator"] = 'exclude';
        if(grid.master && grid.master instanceof Array) {
          grid.master.push($.map(master, function(o){return o;}));
        } else {
          grid.master = master;
        }
      });
    });
  },

  // Attach
  appendNewRecordToMiddleTable: function(masterId, modalId) {
    var self = this;
    var middleModel = this.target.model;
    var $modal = $(modalId);
    var detailGridName = $modal.find(".grid_container").attr("name");
    var detailGrid = gridManager.getGrid(detailGridName);
    var detailIds = detailGrid.getSelectedIds();

    if(detailIds.length === 0) {
      displayErrorMessage("Please select at least one item.");
    } else {
      var data = {master_column: this.target.master.filter_column, master_id: masterId, detail_model: this.model, detail_ids: detailIds, model: middleModel};
      $.post('/wulin_master/attach_details', data, function(response){
        displayNewNotification(response.message);
        $modal.modal('hide');
        self.target.loader.reloadData();
        // reload master grid (in some cases, attaching a detail will affect the master record's data)
        if(self.reload_master && self.target.master_grid) {
          self.target.master_grid.loader.reloadData();
        }
      });
    }
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.AddDetail);