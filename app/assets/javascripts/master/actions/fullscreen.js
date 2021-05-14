WulinMaster.actions.fullscreen = {
  ...WulinMaster.actions.BaseAction,
  name: 'fullscreen',
  handler: function (e, args) {
    let $fullscreenElement = $(e.currentTarget)
    let grid = this.getGrid()
    let currentContainer = grid.container

    toggleSiblings(currentContainer)

    transform($fullscreenElement, currentContainer)

    switchIcon($fullscreenElement)
  },
}

const toggleSiblings = (currentContainer) => {
  Array.from(currentContainer.siblings(':not(script)')).forEach((sbl) =>
    $(sbl).toggle()
  )
}

const transform = ($target, currentContainer) => {
  let isFullscreen = $target.data('fullscreen')
  if (isFullscreen) {
    let gridOriginalHeight = $target.data('grid_height')
    let gridOriginalWidth = $target.data('grid_width')

    $target.removeData('fullscreen', 'grid_height', 'grid_width')

    currentContainer.height(gridOriginalHeight).width(gridOriginalWidth)
  } else {
    let gridContainerHeight = currentContainer[0].style.height
    let gridContainerWidth = currentContainer[0].style.width

    $target.data({
      fullscreen: true,
      grid_width: gridContainerWidth,
      grid_height: gridContainerHeight,
    })

    currentContainer.height('100%').width('100%')
  }
  currentContainer.resize()
}

const switchIcon = ($target) => {
  let $icon = $target.find('a.fullscreen_action, i.material-icons')
  let $iconText = $icon.text()
  $icon.text($iconText === 'fullscreen' ? 'fullscreen_exit' : 'fullscreen')
  let $iconLabel = $target.find('a.fullscreen_action, span')
  let $iconLabelText = $iconLabel.text()
  $iconLabel.text(
    $iconLabelText === 'Fullscreen' ? 'Exit Fullscreen' : 'Fullscreen'
  )
}

WulinMaster.ActionManager.register(WulinMaster.actions.fullscreen)