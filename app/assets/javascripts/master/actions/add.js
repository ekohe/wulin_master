// Toolbar Item 'Add'

WulinMaster.actions.Add = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'add',

  handler: function() {
    var grid = this.getGrid();

    Ui.openDialog(grid.name, grid.extend_options);

    // register 'Create' button click event, need to remove to dialog action later
    $('#' + grid.name + '_submit').on('click', function() {
      createByAjax(grid, false);
      return false;
    });
    // register 'Create and Continue' button click event, need to remove to dialog action later
    $('#' + grid.name + '_submit_continue').on('click', function() {
      createByAjax(grid, true);
      return false;
    });
  }
});

// Record create along ajax
var createByAjax = function(grid, continue_on) {
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
        grid.loader.reloadData();
        if (!continue_on) { 
          Ui.resetForm(grid.name);
          if (grid.loader.isDataLoaded()) {
            setTimeout(function(){
              Ui.closeDialog(grid.name);
            }, 100);
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
}


WulinMaster.ActionManager.register(WulinMaster.actions.Add);
