WulinMaster.actions.fullscreen = {
  ...WulinMaster.actions.BaseAction,
  name: 'fullscreen',

  handler: function (e, args) {
    let $fullscreen = $(e.currentTarget);
    let fullscreen = $fullscreen.data('fullscreen');
    let grid = this.getGrid();
    Array.from(grid.container.siblings(':not(script)')).forEach((sbl) =>
      $(sbl).toggle()
    );
    if (fullscreen) {
      $fullscreen.removeData('fullscreen');
      grid.container
        .height($fullscreen.data('grid_height'))
        .width($fullscreen.data('grid_width'));
      $fullscreen
        .find('a.fullscreen_action, i.material-icons')
        .text('fullscreen');
      $fullscreen.find('a.fullscreen_action, span').text('Fullscreen');
    } else {
      // set data[fullscreen] as true
      $fullscreen.data('fullscreen', true);
      // save grid height and width(don't use jQuery's css function because that will give you the calculated height)
      let gridContainerHeight = grid.container[0].style.height;
      let gridContainerWidth = grid.container[0].style.width;
      $fullscreen.data('grid_height', gridContainerHeight);
      $fullscreen.data('grid_width', gridContainerWidth);
      // show the current grid and set it height 100% width 100%
      grid.container.height('100%').width('100%');
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
