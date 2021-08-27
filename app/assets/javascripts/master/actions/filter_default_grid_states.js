WulinMaster.actions.FilterDefaultGridStates = $.extend(
  {},
  WulinMaster.actions.BaseAction,
  {
    name: "filter_default_grid_states",

    activate: function () {
      var grid = this.getGrid();
      if (!grid) return false;

      var $switcher = $(".filter_default_grid_state input");
      if ($switcher.length == 0) return false;

      $switcher.on("click", function () {
        if ($switcher.is(":checked")) {
          grid.loader.setParam("default_grids", "true", true);
        } else {
          grid.loader.setParam("default_grids", "", true);
        }
      });
    },
  }
);

WulinMaster.ActionManager.register(WulinMaster.actions.FilterDefaultGridStates);
