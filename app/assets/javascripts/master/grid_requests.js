// ------------------------------ CRUD -------------------------------------
var Requests = {
  // Record create by ajax
  createByAjax: function(grid, continue_on, afterCreated) {
    var createFormElement, ajaxOptions, submitButton;
    createFormElement = $('div#'+grid.name+'_form form');
    submitButton = createFormElement.find("input[type='submit']");
    // clear all the error messages
    createFormElement.find(".field_error").text("");
    ajaxOptions = {
      url: grid.path + '.json',
      beforeSend: function() {
        submitButton.prop('disabled', 'disabled');
      },
      success: function(request) {
        if (typeof afterCreated == "function") {
          return afterCreated(request);
        }
        if (request.success) {
          grid.resetActiveCell();
          grid.operatedIds = [request.id];
          var vp = grid.getViewport();

          grid.loader.reloadData();
          grid.loader.ensureData(vp.top, vp.bottom)
          if ((grid.reloadMasterAfterUpdates || grid.options.reloadMasterAfterUpdates) && grid.master_grid) {
            grid.master_grid.loader.reloadData();
            grid.master_grid.loader.ensureData(vp.top, vp.bottom)
          }
          if (continue_on) {
            if (window._always_reset_form) {
              Ui.refreshCreateForm(grid);
            }
          } else {
            if (grid.loader.isDataLoaded()) {
              setTimeout(function(){ Ui.closeModal(grid.name); }, 100);
            }
          }
          displayNewNotification(grid.model + ' successfully created');
        } else {
          for(var k in request.error_message){
            createFormElement.find(".field[name=" + k + "], .field[name=" + k + "_id]").find(".field_error").text(request.error_message[k].join());
            createFormElement.find(".field[name=" + k + "], .field[name=" + k + "_id]").find("input:not(.numInput)").addClass('invalid');
          }
          if (request.error_message['base']) {
            $('.base_error', createFormElement).text(request.error_message['base']);
          }
          saveMessage('Error creating ' + grid.model.toLowerCase(), 'error');
        }
      },
      complete: function() {
        submitButton.prop('disabled', null);
      }
    };
    createFormElement.ajaxSubmit(ajaxOptions);
  },

  // Record update by ajax
  updateByAjax: function(grid, item, editCommand) {
    delete item.slick_index;
    var currentRow = this.getCurrentRows(grid, [item.id])[1];
    $.ajax({
      type: "POST",
      dateType: 'json',
      url: grid.path + "/" + item.id + ".json" + grid.query,
      data: {_method: 'PUT', item: item, authenticity_token: decodeURIComponent(window._token)},
      success: function(msg) {
        if(msg.success) {
          grid.onUpdatedByAjax.notify({item, msg});

          var from = parseInt(currentRow / 200, 10) * 200;
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
    if (ids.length > 350) {
      displayErrorMessage('You select too many rows, please select less than 350 rows.');
      return;
    }
    if(force === undefined) force = false;
    var range = this.getCurrentRows(grid, ids);
    if (ids.length == 0) return;
    $.ajax({
      type: 'POST',
      url: grid.path + '/' + ids + '.json' + grid.query + '&force=' + force,
      data: decodeURIComponent($.param({_method: 'DELETE', authenticity_token: window._token})),
      success: function(msg) {
        if(msg.success) {
          grid.resetActiveCell();
          var from = parseInt(range[0] / 200, 10) * 200;
          var to = range[1]+1;
          grid.loader.reloadData(from, to);
          if ((grid.reloadMasterAfterUpdates || grid.options.reloadMasterAfterUpdates) && grid.master_grid) {
            grid.master_grid.loader.reloadData();
          }

          var buttonMode = grid.container.find('.toolbar-select').data('mode');
          var isSplitMode = buttonMode === 'split';
          var toolbarSelect = grid.container.find('.toolbar-select');
          if(isSplitMode) {
            toolbarSelect.attr('hidden', true);
          } else {
            toolbarSelect
              .find('.specific')
              .addClass('toolbar_icon_disabled')
              .removeClass('specific')
              .addClass('static-waves-effect')
              .removeClass('waves-effect');
          }

          var recordSize = $.isArray(ids) ? ids.length : ids.split(',').length;
          var message;
          if (recordSize > 1) {
            message = recordSize + ' ' + grid.model.toLowerCase() + 's deleted';
          } else {
            message = '1 ' + grid.model.toLowerCase() + ' deleted';
          }
          displayNewNotification(message);
        } else if(msg.confirm) {
          if(msg.warning_message) $('#confirm-content').text(msg.warning_message);
          $('#confirm-modal').modal('open');
          $('#confirmed-btn').off('click').on('click', function() {
            Requests.deleteByAjax(grid, ids, true);
          });
        } else {
          displayErrorMessage(msg.error_message);
          saveMessage('Error deleting ' + grid.model.toLowerCase(), 'error');
        }
      }
    });
  },

  getCurrentRows: function(grid, ids) {
    var indexes = ids.filter((id) => {
      grid.getRowByRecordId(id)
    }).map((id) => parseInt(grid.getRowByRecordId(id).index, 10));
    indexes = indexes.sort();
    return [indexes[0], indexes[indexes.length-1]];
  }
}; // Requests
