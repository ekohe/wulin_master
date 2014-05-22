// Enable multiple states for a grid, render a dropbox to switch states

WulinMaster.actions.MultipleGridStates = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'multiple_grid_states',

  activate: function() {
    var grid = this.getGrid();
    if(!grid) return false;

    var $switcher = $(".grid_states_switcher select");
    if($switcher.length === 0) return false;

    // chosen the dropdown
    $switcher.chosen({search_contains: true});

    // main event, change grid state template
    $switcher.bind("change", function(){
      var state_id = $(this).val();
      $.ajax({
        type: 'POST',
        url:  '/wulin_master/grid_states_manages/update',
        data: { id: state_id, authenticity_token: decodeURIComponent(window._token) },
        success: function(msg) {
          if(msg == "success") {
            var grid_url = grid.path + grid.query;
            $.get(grid_url, function(data){
              grid.container.html(data);
            });
          } else {
            displayErrorMessage(msg);
          }
        }
      });
    });
  }
});


WulinMaster.ActionManager.register(WulinMaster.actions.MultipleGridStates);
