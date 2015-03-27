// Toolbar Item 'Add Detail' for detail grid

WulinMaster.actions.DetailAdd = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'detail_add',

  handler: function(e) {
    var self = this;
    var grid = this.getGrid();
    var hiddenColumns = this.hidden_columns;
    var masterId = this.target.master.filter_value;
    
    Ui.openDialog(grid, 'wulin_master_new_form', grid.options);

    // register 'Create' button click event, need to remove to dialog action later
    $('body').off("click", '#' + grid.name + '_submit').on('click', '#' + grid.name + '_submit', function(evt) {
      if(hiddenColumns) self.fillHiddenColumns(grid, hiddenColumns);

      var e = jQuery.Event('beforesubmit.wulin', {target: this});

      var _cancel = false;
      cancel = function() { _cancel = true; }

      $(this).parents('form').trigger(e, cancel);

      if(_cancel) {
        return false;
      }

      self.afterOpenDialog();
      Requests.createByAjax(grid, false);
      return false;
    });
    // register 'Create and Continue' button click event, need to remove to dialog action later
    $('body').off("click", '#' + grid.name + '_submit_continue').on('click', '#' + grid.name + '_submit_continue', function(evt) {
      if(hiddenColumns) self.fillHiddenColumns(grid, hiddenColumns);

      var e = jQuery.Event('beforesubmit.wulin', {target: this});

      var _cancel = false;
      cancel = function() { _cancel = true; }

      $(this).parents('form').trigger(e, cancel);

      if(_cancel) {
        return false;
      }

      self.afterOpenDialog();
      Requests.createByAjax(grid, true);
      return false;
    });
  },

  fillHiddenColumns: function(grid, hiddenColumns) {
    var self = this;
    if(!hiddenColumns instanceof Array) return false;

    var currentFilters = grid.loader.getFilters();
    $.each(currentFilters, function(index, filter) {
      if(hiddenColumns.indexOf(filter[0]) != -1) {
        self.addHiddenColumn(filter[0], filter[1]);
      }
    });
  },

  addHiddenColumn: function(column, value) {
    var $createForm = $(".create_form form");
    var model = $createForm.attr("id").replace("new_", "");
    $('<input/>').attr("id", model + "_" + column).attr("type", "hidden").attr("value", value).attr("name", model + '[' + column + ']').appendTo($createForm);
  }


  afterOpenDialog: function() {
    var $form = $('#new_vehicule_assignment');
    $form.prepend('<input type="hidden" value="' + masterId + '" name="vehicule_assignment[vehicule_usage_id]">');
  }


//   handler: function(e) {
//     var self = this;
//     var masterId = this.target.master.filter_value;
//     var options = {
//       autoOpen: true,
//       width: 750,
//       height: 600,
//       buttons: {
//         Attach: function() {
//           self.appendNewRecordToMiddleTable(masterId, $modelDialog);
//         },
//         Cancel: function() {
//           $(this).dialog( "destroy" );
//           $modelDialog.remove();
//         }
//       },
//       close: function() {
//         $(this).dialog("destroy");
//         $modelDialog.remove();
//       },
//       open: function(event, ui) {
//         self.getModelGrid(masterId, $modelDialog);
//       }
//     };
//     var $modelDialog = $("<div/>").attr({id: this.model + '_dialog', title: "Attach"}).css('display', 'none').appendTo($('body'));
//     if (this.dialog_options && $.isPlainObject(this.dialog_options)) {
//       $.extend(options, this.dialog_options);
//     }
//     $modelDialog.dialog(options);
//   },
  
//   getModelGrid: function(masterId, dialogDom) {
//     var master = $.extend({}, this.target.master);
//     var screen = this.screen;
//     // first get controller of the detail model, then open the dialog fill the detail grid
//     $.get('/wulin_master/get_detail_controller?model=' + this.model + '&middle_model=' + this.target.model, function(data){
//       var url = "/" + data.controller + "?screen=" + screen + "&filters[][column]=" + master.filter_column + "&filters[][value]=" + masterId + "&filters[][operator]=exclude";
//       $.ajax({
//         type: 'GET',
//         url: url
//       })
//       .success(function(response){
//         dialogDom.html(response);
//         // copy the target's master to detail grid, just replace the operator to 'exclude'
//         var gridName = dialogDom.find(".grid_container").attr("name");
//         var grid = gridManager.getGrid(gridName);
//         master["filter_operator"] = 'exclude';
//         if(grid.master && grid.master instanceof Array) {
//           grid.master.push($.map(master, function(o){return o;}));
//         } else {
//           grid.master = master;
//         }
//       });
//     });
//   },
  
//   // Attach
//   appendNewRecordToMiddleTable: function(masterId, dialogDom) {
//     var self = this;
//     var middleModel = this.target.model;
//     var detailGridName = dialogDom.find(".grid_container").attr("name");
//     var detailGrid = gridManager.getGrid(detailGridName);
//     var detailIds = detailGrid.getSelectedIds();
    
//     if(detailIds.length === 0) {
//       displayErrorMessage("Please select at least one item.");
//     } else {
//       var data = {master_column: this.target.master.filter_column, master_id: masterId, detail_model: middleModel , detail_ids: detailIds, model: this.model};
//       $.post('/wulin_master/attach_master_details', data, function(response){
//         displayNewNotification(response.message);
//         dialogDom.dialog( "destroy" );
//         dialogDom.remove();
//         self.target.loader.reloadData();
//         // reload master grid (in some cases, attaching a detail will affect the master record's data)
//         if(self.reload_master && self.target.master_grid) {
//           self.target.master_grid.loader.reloadData();
//         }
//       });
//     }
//   }

});

WulinMaster.ActionManager.register(WulinMaster.actions.DetailAdd);