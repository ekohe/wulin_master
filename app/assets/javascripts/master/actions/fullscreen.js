WulinMaster.actions.fullscreen = {
  ...WulinMaster.actions.BaseAction,
  name: 'fullscreen',

  handler: function (e, args) {
    let $fullscreen = $(e.currentTarget);
    let fullscreen = $fullscreen.data('fullscreen');
    let grid = this.getGrid();
    let currentContainer = grid.container;
    Array.from(currentContainer.siblings(':not(script)')).forEach((sbl) =>
      $(sbl).toggle()
    );

    if (fullscreen) {
      let gridOriginalHeight = $fullscreen.data('grid_height');
      let gridOriginalWidth = $fullscreen.data('grid_width');
      $fullscreen.removeData('fullscreen', 'grid_height', 'grid_width');
      currentContainer.height(gridOriginalHeight).width(gridOriginalWidth);
    } else {
      $fullscreen.data('fullscreen', true);
      let gridContainerHeight = currentContainer[0].style.height;
      let gridContainerWidth = currentContainer[0].style.width;
      $fullscreen.data('grid_height', gridContainerHeight);
      $fullscreen.data('grid_width', gridContainerWidth);

      currentContainer.height('100%').width('100%');
    }
    currentContainer.resize();

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
