WulinMaster.actions.fullscreen = {
  ...WulinMaster.actions.BaseAction,
  name: 'fullscreen',

  handler: function (e, args) {
    let $fullscreen = $(e.currentTarget);
    let fullscreen = $fullscreen.data('fullscreen');
    let grid = this.getGrid();
    if (fullscreen) {
      $fullscreen.removeData('fullscreen');
      grid.container
        .height($fullscreen.data('grid_height'))
        .width($fullscreen.data('grid_width'))
        .hide();
      gridManager.grids.forEach((_grid) => _grid.container.show());
      $fullscreen
        .find('a.fullscreen_action, i.material-icons')
        .text('fullscreen');
      $fullscreen.find('a.fullscreen_action, span').text('Fullscreen');
    } else {
      // set data[fullscreen] as true
      $fullscreen.data('fullscreen', true);
      // save grid height and width
      $fullscreen.data('grid_height', grid.container.height());
      $fullscreen.data('grid_width', grid.container.width());
      // hide all girds
      gridManager.grids.forEach((_grid) => _grid.container.hide());
      // show the current grid and set it height 100% width 100%
      grid.container.show().height('100%').width('100%');
      // change icon
      $fullscreen
        .find('a.fullscreen_action, i.material-icons')
        .text('fullscreen_exit');
      // change label
      $fullscreen.find('a.fullscreen_action, span').text('Fullscreen Exit');
    }
  },
};

WulinMaster.ActionManager.register(WulinMaster.actions.fullscreen);
