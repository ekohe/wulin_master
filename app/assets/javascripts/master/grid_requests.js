// ------------------------------ CRUD -------------------------------------
var Requests = {
  // Record create by ajax
  createByAjax: function(grid, continue_on, afterCreated) {
    var createFormElement, ajaxOptions;
    createFormElement = $('div#' + grid.name + '_form form');
    // clear all the error messages
    createFormElement.find(".field_error").text("");
    ajaxOptions = {
      url: grid.path + '.json',
      success: function(request) {
        if (typeof afterCreated == "function") {
          return afterCreated(request);
        }
        if (request.success) {
          grid.resetActiveCell();
          grid.operatedIds = [request.id];
          grid.loader.reloadData();
          if (continue_on) {
            if (window._always_reset_form) {
              Ui.refreshCreateForm(grid);
            }
          } else {
            if (grid.loader.isDataLoaded()) {
              setTimeout(function() {
                Ui.closeDialog(grid.name);
              }, 100);
            }
          }
          displayNewNotification('Record successfully created!');
        } else {
          for (var k in request.error_message) {
            createFormElement.find(".field[name=" + k + "]").find(".field_error").text(request.error_message[k].join());
          }
          if (request.error_message['base']) {
            $('.base_error', createFormElement).text(request.error_message['base']);
          }
        }
      }
    };
    createFormElement.ajaxSubmit(ajaxOptions);
  },

  // Record update by ajax
  updateByAjax: function(grid, item, editCommand, successCallback) {
    delete item.slick_index;
    var currentRow = this.getCurrentRows(grid, [item.id])[1];
    $.ajax({
      type: "POST",
      dateType: 'json',
      url: grid.path + "/" + item.id + ".json" + grid.query,
      data: {
        _method: 'PUT',
        item: item,
        authenticity_token: decodeURIComponent(window._token)
      },
      success: function(msg) {
        if (msg.success) {
          var from = parseInt(currentRow / 200, 10) * 200;
          grid.loader.reloadData(from, currentRow);
        } else {
          displayErrorMessage(msg.error_message);
          if (editCommand) {
            editCommand.undo();
          } else {
            grid.loader.reloadData();
          }
        }
        if (successCallback) successCallback();
      }
    });
  },

  // Delete rows along ajax
  deleteByAjax: function(grid, ids, force) {
    if (ids.length > 350) {
      displayErrorMessage('You select too many rows, please select less than 350 rows.');
      return;
    }
    if (force === undefined) force = false;
    var range = this.getCurrentRows(grid, ids);
    $.ajax({
      type: 'POST',
      url: grid.path + '/' + ids + '.json' + grid.query + '&force=' + force,
      data: decodeURIComponent($.param({
        _method: 'DELETE',
        authenticity_token: window._token
      })),
      success: function(msg) {
        if (msg.success) {
          grid.resetActiveCell();
          var from = parseInt(range[0] / 200, 10) * 200;
          var to = range[1] + 1;
          grid.loader.reloadData(from, to);
          var recordSize = $.isArray(ids) ? ids.length : ids.split(',').length;
          var message;
          if (recordSize > 1) {
            message = recordSize + " records deleted.";
          } else {
            message = "1 record deleted.";
          }
          displayNewNotification(message);
        } else if (msg.confirm) {
          $("#confirm_dialog").dialog({
            modal: true,
            open: function() {
              if (msg.warning_message) $(this).find('#confirm_content').text(msg.warning_message);
            },
            buttons: {
              Confirm: function() {
                Requests.deleteByAjax(grid, ids, true);
                $("#confirm_dialog").dialog("close");
              },
              Cancel: function() {
                $("#confirm_dialog").dialog("close");
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
  },

  getCurrentRows: function(grid, ids) {
    var indexes = $.map(ids, function(id) {
      return parseInt(grid.getRowByRecordId(id).index, 10);
    });
    indexes = indexes.sort();
    return [indexes[0], indexes[indexes.length - 1]];
  }
}; // Requests
