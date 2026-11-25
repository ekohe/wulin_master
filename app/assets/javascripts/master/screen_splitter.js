// Drag the border between the two grids of a screen to resize them. The sizes are saved per user
// and screen in user preferences, and Screen#grid_sizes renders them on the next load.
// Double-click the border to go back to the sizes set in the screen class.
// Each grid keeps its min_width or min_height (px) from Screen.grid. Side by side, a grid also
// keeps room for its title and header filters, which do not shrink, and the more button.
// A window resize keeps these minimums but does not save: a bigger window brings the saved size back.
window.ScreenSplitter = {
  init: function() {
    const $screen = $('#screen_content');
    // #screen_content and window stay when the next screen loads
    $(window).off('resize.screenSplitter');
    $screen.css('min-width', '');
    const $grids = $screen.children('.grid_container');
    if ($grids.length !== 2 || $screen.children('.panel_container').length || $grids.data('resizable') === false) return;

    const sideBySide = Math.abs($grids.eq(0).offset().top - $grids.eq(1).offset().top) < 2;
    const dimension = sideBySide ? 'width' : 'height';
    const edge = sideBySide ? 'left' : 'top';
    // The grid on the left (or on top) comes first, whatever the DOM order
    const $firstGrid = $grids.eq($grids.eq(0).offset()[edge] <= $grids.eq(1).offset()[edge] ? 0 : 1);
    const $secondGrid = $grids.not($firstGrid);
    const screenClass = $firstGrid.data('screen');
    const outerDimension = sideBySide ? 'outerWidth' : 'outerHeight';
    const minDataKey = sideBySide ? 'minWidth' : 'minHeight';
    const screenSize = () => sideBySide ? $screen.width() : $screen.height();
    let firstMin, secondMin;
    // Size of the first grid in percent, with both grids at or above their minimum
    const clampedPercent = (firstSize) => {
      const total = screenSize();
      return Math.round(Math.min(Math.max(firstSize, firstMin), total - secondMin) / total * 1000) / 10;
    };
    // Measured again on each resize and drag: the title changes with the selected rows. 43px is the more button
    // with its buffer in Slick.Grid#restoreButtons, which folds the other toolbar buttons into it.
    const headerMinWidth = ($grid) => {
      const title = $grid.find('> .grid-header > .title-with-actions')[0];
      if (!sideBySide || !title) return 0;
      const inlineWidth = title.style.width;
      title.style.width = 'max-content';
      const titleWidth = title.getBoundingClientRect().width;
      title.style.width = inlineWidth;
      const $toolbar = $grid.find('> .grid-header > .toolbar-wrapper');
      return Math.ceil(titleWidth + $toolbar.outerWidth() - $toolbar.width() + 43);
    };
    const measureMinimums = () => {
      firstMin = Math.max($firstGrid.data(minDataKey), headerMinWidth($firstGrid));
      secondMin = Math.max($secondGrid.data(minDataKey), headerMinWidth($secondGrid));
    };
    // The saved (or screen) size; the shown size differs only while it is clamped
    let firstPercent = $firstGrid[outerDimension]() / screenSize() * 100;
    let shownPercent = firstPercent;

    const $splitter = $('<div />').addClass(`screen-splitter screen-splitter-${dimension}`).css(edge, `${firstPercent}%`).appendTo($screen);
    const applySizes = (percent) => {
      shownPercent = percent;
      $firstGrid.css(dimension, `${percent}%`);
      $secondGrid.css(dimension, `${100 - percent}%`);
      $splitter.css(edge, `${percent}%`);
      gridManager.resizeGrids();
      // Fold the toolbar buttons that do not fit into the more button, as on a window resize
      $.each(gridManager.grids, function() {
        if ($grids.is(`#grid_${this.name}`)) this.restoreButtons();
      });
    };

    const fit = () => {
      measureMinimums();
      if (sideBySide) $screen.css('min-width', firstMin + secondMin);
      const total = screenSize();
      const firstSize = firstPercent / 100 * total;
      const percent = firstSize < firstMin || total - firstSize < secondMin ? clampedPercent(firstSize) : firstPercent;
      if (percent !== shownPercent) applySizes(percent);
    };
    fit();
    $(window).on('resize.screenSplitter', fit);

    $splitter.on('mousedown', (e) => {
      e.preventDefault();
      $('body').addClass('screen-splitter-dragging');
      let moved = false;
      measureMinimums();

      $(document).on('mousemove.screenSplitter', (e) => {
        moved = true;
        firstPercent = clampedPercent(sideBySide ? e.pageX - $screen.offset().left : e.pageY - $screen.offset().top);
        applySizes(firstPercent);
      });

      $(document).one('mouseup.screenSplitter', () => {
        $(document).off('mousemove.screenSplitter');
        $('body').removeClass('screen-splitter-dragging');
        // A click, or each click of a double-click, must not save: a late PUT would undo the reset
        if (!moved) return;

        const sizes = {
          [$firstGrid.data('gridClass')]: {[dimension]: `${firstPercent}%`},
          [$secondGrid.data('gridClass')]: {[dimension]: `${100 - firstPercent}%`}
        };
        this.request('PUT', screenClass, {value: JSON.stringify(sizes)});
      });
    });

    $splitter.on('dblclick', () => {
      this.request('DELETE', screenClass).done(() => load_page(History.getState().url));
    });
  },

  request: function(type, screenClass, data) {
    return $.ajax({
      type: type,
      url: `/wulin_master/user_preferences/${screenClass}`,
      headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
      data: data,
      dataType: 'json'
    });
  }
};
