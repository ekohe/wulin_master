// Enable multiple states for a grid, render a dropbox to switch states

WulinMaster.actions.MultipleGridStates = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'multiple_grid_states',

  activate: function() {
    var grid = this.getGrid();
    if(!grid) return false;

    var $stateItems = $(`#grid_states_${grid.name} .grid-state-item`);
    if($stateItems.length === 0) return false;

    // main event, change grid state template
    $stateItems.on("click", function(){
      var stateId = $(this).attr('data-state-id');
      $.ajax({
        type: 'POST',
        url:  '/wulin_master/grid_states_manages/set_current',
        data: { id: stateId, authenticity_token: decodeURIComponent(window._token) },
        success: function(msg) {
          if(msg == "success") {
            location.reload()
          } else {
            displayErrorMessage(msg);
          }
        }
      });
    });
  }
});


WulinMaster.ActionManager.register(WulinMaster.actions.MultipleGridStates);
