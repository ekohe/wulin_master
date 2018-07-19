(function ($) {
  function SlickGridPager(dataView, grid, $container, options) {
    var $status;
    var _options;
    var _defaults = {
      showAllText: "Showing all {rowCount} rows",
      showPageText: "Showing page {pageNum} of {pageCount}"
    };

    // Ekohe Add
    var $clearFilterLink;

    function init() {
      _options = $.extend(true, {}, _defaults, options);

      dataView.onPagingInfoChanged.subscribe(function (e, pagingInfo) {
        // EKohe Edit: Use customized update logic (Add row count without filter)
        // updatePager(pagingInfo);
        wulinUpdatePager(pagingInfo);
      });

      // Ekohe Edit: Use customized pager UI (Remove pagging btns, Add clear filter link)
      // constructPagerUI();
      wulinConstructPagerUI();

      // Ekohe Delete: Triggerd by onPagingInfoChanged event, no need here
      // updatePager(dataView.getPagingInfo());
    }

    function getNavState() {
      var cannotLeaveEditMode = !Slick.GlobalEditorLock.commitCurrentEdit();
      var pagingInfo = dataView.getPagingInfo();
      var lastPage = pagingInfo.totalPages - 1;

      return {
        canGotoFirst: !cannotLeaveEditMode && pagingInfo.pageSize != 0 && pagingInfo.pageNum > 0,
        canGotoLast: !cannotLeaveEditMode && pagingInfo.pageSize != 0 && pagingInfo.pageNum != lastPage,
        canGotoPrev: !cannotLeaveEditMode && pagingInfo.pageSize != 0 && pagingInfo.pageNum > 0,
        canGotoNext: !cannotLeaveEditMode && pagingInfo.pageSize != 0 && pagingInfo.pageNum < lastPage,
        pagingInfo: pagingInfo
      }
    }

    function setPageSize(n) {
      dataView.setRefreshHints({
        isFilterUnchanged: true
      });
      dataView.setPagingOptions({pageSize: n});
    }

    function gotoFirst() {
      if (getNavState().canGotoFirst) {
        dataView.setPagingOptions({pageNum: 0});
      }
    }

    function gotoLast() {
      var state = getNavState();
      if (state.canGotoLast) {
        dataView.setPagingOptions({pageNum: state.pagingInfo.totalPages - 1});
      }
    }

    function gotoPrev() {
      var state = getNavState();
      if (state.canGotoPrev) {
        dataView.setPagingOptions({pageNum: state.pagingInfo.pageNum - 1});
      }
    }

    function gotoNext() {
      var state = getNavState();
      if (state.canGotoNext) {
        dataView.setPagingOptions({pageNum: state.pagingInfo.pageNum + 1});
      }
    }

    function constructPagerUI() {
      $container.empty();

      var $nav = $("<span class='slick-pager-nav' />").appendTo($container);
      var $settings = $("<span class='slick-pager-settings' />").appendTo($container);
      $status = $("<span class='slick-pager-status' />").appendTo($container);

      $settings
          .append("<span class='slick-pager-settings-expanded' style='display:none'>Show: <a data=0>All</a><a data='-1'>Auto</a><a data=25>25</a><a data=50>50</a><a data=100>100</a></span>");

      $settings.find("a[data]").click(function (e) {
        var pagesize = $(e.target).attr("data");
        if (pagesize != undefined) {
          if (pagesize == -1) {
            var vp = grid.getViewport();
            setPageSize(vp.bottom - vp.top);
          } else {
            setPageSize(parseInt(pagesize));
          }
        }
      });

      var icon_prefix = "<span class='ui-state-default ui-corner-all ui-icon-container'><span class='ui-icon ";
      var icon_suffix = "' /></span>";

      $(icon_prefix + "ui-icon-lightbulb" + icon_suffix)
          .click(function () {
            $(".slick-pager-settings-expanded").toggle()
          })
          .appendTo($settings);

      $(icon_prefix + "ui-icon-seek-first" + icon_suffix)
          .click(gotoFirst)
          .appendTo($nav);

      $(icon_prefix + "ui-icon-seek-prev" + icon_suffix)
          .click(gotoPrev)
          .appendTo($nav);

      $(icon_prefix + "ui-icon-seek-next" + icon_suffix)
          .click(gotoNext)
          .appendTo($nav);

      $(icon_prefix + "ui-icon-seek-end" + icon_suffix)
          .click(gotoLast)
          .appendTo($nav);

      $container.find(".ui-icon-container")
          .hover(function () {
            $(this).toggleClass("ui-state-hover");
          });

      $container.children().wrapAll("<div class='slick-pager' />");
    }

    ////////////////////////////////////////////////////////////////////////////
    // Ekohe Add: Customized constructPagerUI
    //   1. Remove pagging fucntion (Wulin Master loads data by scrolling)
    //   2. Show rows count info (filtered count/all count)
    //   3. Show Clear filter link

    function wulinConstructPagerUI() {
      $container.empty();
      $status = $("<span class='slick-pager-status' />").appendTo($container);

      // Ekohe Add: Clear Filter
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

    function updatePager(pagingInfo) {
      var state = getNavState();

      $container.find(".slick-pager-nav span").removeClass("ui-state-disabled");
      if (!state.canGotoFirst) {
        $container.find(".ui-icon-seek-first").addClass("ui-state-disabled");
      }
      if (!state.canGotoLast) {
        $container.find(".ui-icon-seek-end").addClass("ui-state-disabled");
      }
      if (!state.canGotoNext) {
        $container.find(".ui-icon-seek-next").addClass("ui-state-disabled");
      }
      if (!state.canGotoPrev) {
        $container.find(".ui-icon-seek-prev").addClass("ui-state-disabled");
      }

      if (pagingInfo.pageSize == 0) {
        $status.text(_options.showAllText.replace('{rowCount}', pagingInfo.totalRows + "").replace('{pageCount}', pagingInfo.totalPages + ""));
      } else {
        $status.text(_options.showPageText.replace('{pageNum}', pagingInfo.pageNum + 1 + "").replace('{pageCount}', pagingInfo.totalPages + ""));
      }
    }

    ////////////////////////////////////////////////////////////////////////////
    // Ekohe Add: Customized updatePager
    //   1. Show rows count as `14(filtered) of 100(all) rows found`

    function wulinUpdatePager(pagingInfo) {
      if (pagingInfo.pageSize == 0) {
        if (grid.getFilteredInputs().length == 0) {
          $status.text(pagingInfo.totalRows.toLocaleString() + " rows found");
          $status.removeClass('with-filter');
          $clearFilterLink.addClass('hide');
        } else {
          $status.text(pagingInfo.totalRows.toLocaleString() + " of " + pagingInfo.rowsWithoutFilter.toLocaleString() + " rows found");
          $status.addClass('with-filter');
          $clearFilterLink.removeClass('hide');
        }
      } else {
        $status.text("Showing page " + (pagingInfo.pageNum+1) + " of " + (Math.floor(pagingInfo.totalRows/pagingInfo.pageSize)+1));
      }
    }

    ////////////////////////////////////////////////////////////////////////////
    // Ekohe Add: Customized API

    function resetPager() {
      wulinUpdatePager({pageSize:0, pageNum:0, totalRows:0, rowsWithoutFilter:0});
    }

    function clearPager() {
      $status.text('');
    }

    init();

    // Ekohe Add: Expose API methods
    return {
      "resetPager": resetPager,
      "clearPager": clearPager
    };
  }

  // Slick.Controls.Pager
  $.extend(true, window, { Slick:{ Controls:{ Pager:SlickGridPager }}});
})(jQuery);
