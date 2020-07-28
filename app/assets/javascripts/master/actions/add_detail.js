// Toolbar Item 'Add Detail' for detail grid

WulinMaster.actions.AddDetail = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'add_detail',

  handler: function(e) {
    var self = this;
    var masterId = this.target.master.filter_value;

    var $addDetailModal = Ui.headerModal('Attach', {
      onOpenStart: function (modal, trigger) {
        self.getModelGrid(masterId, $(modal).find('.modal-content'));
        $(modal).find('.modal-content').css('padding', '0');
      },
    });

    var $modalFooter = Ui.modalFooter('Attach').appendTo($addDetailModal);
    $modalFooter.find('.confirm-btn').addClass('disabled').on('click', function() {
      self.appendNewRecordToMiddleTable(masterId, $addDetailModal.find('.modal-content'));
    });
  },

  getModelGrid: function(masterId, modalContentDom) {
    var self = this;
    var master = $.extend({}, this.target.master);
    var screen = this.screen;

    $.get('/wulin_master/detail_controller?model=' + this.model + '&middle_model=' + this.target.model, function(data){
      var url = "/" + data.controller + "?screen=" + screen + "&filters[][column]=" + master.filter_column + "&filters[][value]=" + masterId + "&filters[][operator]=exclude";
      $.ajax({
        type: 'GET',
        url: url
      })
      .success(function(response){
        modalContentDom.html(response);

        // copy the target's master to detail grid, just replace the operator to 'exclude'
        var gridName = modalContentDom.find(".grid_container").attr("name");
        var grid = gridManager.getGrid(gridName);
        master["filter_operator"] = 'exclude';
        if(grid.master && grid.master instanceof Array) {
          grid.master.push($.map(master, function(o){return o;}));
        } else {
          grid.master = master;
        }

        self.setGridHeightInModal(modalContentDom.parent());
      });
    });
  },

  // Attach
  appendNewRecordToMiddleTable: function(masterId, dialogDom) {
    var self = this;
    var middleModel = this.target.model;
    var detailGridName = dialogDom.find(".grid_container").attr("name");
    var detailGrid = gridManager.getGrid(detailGridName);
    var detailIds = detailGrid.getSelectedIds();
    var data = {master_column: this.target.master.filter_column, master_id: masterId, detail_model: this.model, detail_ids: detailIds, model: middleModel};
    $.post('/wulin_master/attach_details', data, function(response){
      displayNewNotification(response.message);
      dialogDom.parent().modal('close');
      self.target.loader.reloadData();
      // reload master grid (in some cases, attaching a detail will affect the master record's data)
      if(self.reload_master && self.target.master_grid) {
        self.target.master_grid.loader.reloadData();
      }
    });
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.AddDetail);
