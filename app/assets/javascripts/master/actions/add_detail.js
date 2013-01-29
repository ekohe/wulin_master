// Toolbar Item 'Add Detail' for detail grid

WulinMaster.actions.AddDetail = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'add_detail',

  handler: function(e) {
    var self = this;
    var masterId = this.target.master.filter_value;
    var options = {
      autoOpen: true,
      width: 750,
      height: 600,
      buttons: {
        Attach: function() {
          self.appendNewRecordToMiddleTable(masterId, $modelDialog);
        },
        Cancel: function() {
          $(this).dialog( "destroy" );
          $modelDialog.remove();
        }
      },
      close: function() {
        $(this).dialog("destroy");
        $modelDialog.remove();
      },
      open: function(event, ui) {
        self.getModelGrid(masterId, $modelDialog);
      }
    };
    var $modelDialog = $("<div/>").attr({id: this.model + '_dialog', title: "Attach"}).css('display', 'none').appendTo($('body'));
    if (this.dialog_options && $.isPlainObject(this.dialog_options)) {
      $.extend(options, this.dialog_options);
    }
    $modelDialog.dialog(options);
  },
  
  getModelGrid: function(masterId, dialogDom) {
    var master = $.extend({}, this.target.master);
    var screen = this.screen;
    // first get controller of the detail model, then open the dialog fill the detail grid
    $.get('/wulin_master/get_detail_controller?model=' + this.model + '&middle_model=' + this.target.model, function(data){
      var url = "/" + data.controller + "?screen=" + screen + "&filters[][column]=" + master.filter_column + "&filters[][value]=" + masterId + "&filters[][operator]=exclude";
      $.ajax({
        type: 'GET',
        url: url
      })
      .success(function(response){
        dialogDom.html(response);
        // copy the target's master to detail grid, just replace the operator to 'exclude'
        var gridName = dialogDom.find(".grid_container").attr("name");
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
  appendNewRecordToMiddleTable: function(masterId, dialogDom) {
    var self = this;
    var middleModel = this.target.model;
    var detailGridName = dialogDom.find(".grid_container").attr("name");
    var detailGrid = gridManager.getGrid(detailGridName);
    var detailIds = detailGrid.getSelectedIds();
    
    if(detailIds.length === 0) {
      displayErrorMessage("Please select at least one item.");
    } else {
      var data = {master_column: this.target.master.filter_column, master_id: masterId, detail_model: this.model, detail_ids: detailIds, model: middleModel};
      $.post('/wulin_master/attach_details', data, function(response){
        displayNewNotification(response.message);
        dialogDom.dialog( "destroy" );
        dialogDom.remove();
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