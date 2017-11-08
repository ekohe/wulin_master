(function($) {
  function SlickGridPager(dataView, grid, $container) {
    var $status, $contextMenu;
    // Ekohe Add
    var $clearFilterLink;

    function init() {
      dataView.onPagingInfoChanged.subscribe(function(e,pagingInfo) {
        updatePager(pagingInfo);
      });

      constructPagerUI();
    }

    function getNavState() {
      var cannotLeaveEditMode = !Slick.GlobalEditorLock.commitCurrentEdit();
      var pagingInfo = dataView.getPagingInfo();
      var lastPage = Math.floor(pagingInfo.totalRows/pagingInfo.pageSize);

      return {
        canGotoFirst:  !cannotLeaveEditMode && pagingInfo.pageSize != 0 && pagingInfo.pageNum > 0,
        canGotoLast:  !cannotLeaveEditMode && pagingInfo.pageSize != 0 && pagingInfo.pageNum != lastPage,
        canGotoPrev:  !cannotLeaveEditMode && pagingInfo.pageSize != 0 && pagingInfo.pageNum > 0,
        canGotoNext:  !cannotLeaveEditMode && pagingInfo.pageSize != 0 && pagingInfo.pageNum < lastPage,
        pagingInfo:    pagingInfo,
        lastPage:    lastPage
      }
    }

    function setPageSize(n) {
      dataView.setPagingOptions({pageSize:n});
    }

    function gotoFirst() {
      if (getNavState().canGotoFirst)
        dataView.setPagingOptions({pageNum: 0});
    }

    function gotoLast() {
      var state = getNavState();
      if (state.canGotoLast)
        dataView.setPagingOptions({pageNum: state.lastPage});
    }

    function gotoPrev() {
      var state = getNavState();
      if (state.canGotoPrev)
        dataView.setPagingOptions({pageNum: state.pagingInfo.pageNum-1});
    }

    function gotoNext() {
      var state = getNavState();
      if (state.canGotoNext)
        dataView.setPagingOptions({pageNum: state.pagingInfo.pageNum+1});
    }

    function constructPagerUI() {
      $container.empty();
      $status = $("<span class='slick-pager-status' />").appendTo($container);

      // Ekohe Add: Clear Filter
      // $clearFilterLink = $("<a class='right slick-pager-clear-filter' href='#' />").appendTo($container);
      $clearFilterLink = $("<a href='#' />")
        .addClass('slick-pager-clear-filter right hide')
        .append($('<i class="material-icons">close</i>'))
        .append($('<span>CLEAR FILTER</span>'))
        .appendTo($container);

      $container.children().wrapAll("<div class='slick-pager' />");
      $clearFilterLink.on('click', function() {
        grid.container.find('.slick-header-column input').val('').focusout();
        grid.filterPanel.updateCurrentFilters();
        grid.filterPanel.applyCurrentFilters([]);
        grid.filterPanel.setCurrentFilter();
        grid.filterPanel.trigger(grid.filterPanel.onFilterLoaded, {filterData:[]});
      })
    }

    // Ekohe Edit: Show row count without filter
    function updatePager(pagingInfo) {
      // if (pagingInfo.pageSize == 0)
      //   $status.text(pagingInfo.totalRows + " rows found");
      // else
      //   $status.text("Showing page " + (pagingInfo.pageNum+1) + " of " + (Math.floor(pagingInfo.totalRows/pagingInfo.pageSize)+1));

      if (pagingInfo.pageSize == 0) {
        if (grid.getFilteredInputs().length == 0) {
          $status.text(pagingInfo.totalRows + " rows found");
          $status.removeClass('with-filter');
          $clearFilterLink.addClass('hide');
        } else {
          $status.text(pagingInfo.totalRows + " of " + pagingInfo.rowsWithoutFilter + " rows found");
          $status.addClass('with-filter');
          $clearFilterLink.removeClass('hide');
        }
      } else {
        $status.text("Showing page " + (pagingInfo.pageNum+1) + " of " + (Math.floor(pagingInfo.totalRows/pagingInfo.pageSize)+1));
      }
    }

    function resetPager() {
      updatePager({pageSize:0, pageNum:0, totalRows:0});
    }

    function clearPager() {
      $status.text('');
    }

    init();

    return {
      // methods
      "resetPager": resetPager,
      "clearPager": clearPager
    };
  }

  // Slick.Controls.Pager
  $.extend(true, window, { WulinMaster: { Pager: SlickGridPager }});
})(jQuery);
