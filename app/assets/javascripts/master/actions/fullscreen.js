WulinMaster.actions.fullscreen = {
  ...WulinMaster.actions.BaseAction,
  name: 'fullscreen',

  handler: function (e, args) {
    let $fullscreenElement = $(e.currentTarget);
    let fullscreen = $fullscreenElement.data('fullscreen');
    let grid = this.getGrid();
    let currentContainer = grid.container;
    Array.from(currentContainer.siblings(':not(script)')).forEach((sbl) =>
      $(sbl).toggle()
    );

    if (fullscreen) {
      let gridOriginalHeight = $fullscreenElement.data('grid_height');
      let gridOriginalWidth = $fullscreenElement.data('grid_width');
      $fullscreenElement.removeData('fullscreen', 'grid_height', 'grid_width');
      currentContainer.height(gridOriginalHeight).width(gridOriginalWidth);
    } else {
      $fullscreenElement.data('fullscreen', true);
      let gridContainerHeight = currentContainer[0].style.height;
      let gridContainerWidth = currentContainer[0].style.width;
      $fullscreenElement.data('grid_height', gridContainerHeight);
      $fullscreenElement.data('grid_width', gridContainerWidth);

      currentContainer.height('100%').width('100%');
    }
    currentContainer.resize();

    switchIcon($fullscreenElement);
  },
};

const switchIcon = ($target) => {
  let $icon = $target.find('a.fullscreen_action, i.material-icons');
  let $iconText = $icon.text();
  $icon.text($iconText === 'fullscreen' ? 'fullscreen_exit' : 'fullscreen');
  let $iconLabel = $target.find('a.fullscreen_action, span');
  let $iconLabelText = $iconLabel.text();
  $iconLabel.text(
    $iconLabelText === 'Fullscreen' ? 'Fullscreen Exit' : 'Fullscreen'
  );
};

WulinMaster.ActionManager.register(WulinMaster.actions.fullscreen);
