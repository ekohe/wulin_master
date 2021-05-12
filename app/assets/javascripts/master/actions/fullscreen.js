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

    let heightWillBeSet = $fullscreen.data('grid_height') || '100%';
    let widthWillBeSet = $fullscreen.data('grid_width') || '100%';

    let gridContainerHeight = grid.container[0].style.height;
    let gridContainerWidth = grid.container[0].style.width;
    $fullscreen.data(
      'grid_height',
      $fullscreen.data('grid_height') ? heightWillBeSet : gridContainerHeight
    );
    $fullscreen.data(
      'grid_width',
      $fullscreen.data('grid_width') ? widthWillBeSet : gridContainerWidth
    );

    grid.container.height(heightWillBeSet).width(widthWillBeSet);

    let $icon = $fullscreen.find('a.fullscreen_action, i.material-icons');
    let $iconText = $icon.text();
    $icon.text($iconText === 'fullscreen' ? 'fullscreen_exit' : 'fullscreen');
    let $iconLabel = $fullscreen.find('a.fullscreen_action, span');
    let $iconLabelText = $iconLabel.text();
    $iconLabel.text(
      $iconLabelText === 'Fullscreen' ? 'Fullscreen Exit' : 'Fullscreen'
    );
  },
};

WulinMaster.ActionManager.register(WulinMaster.actions.fullscreen);
