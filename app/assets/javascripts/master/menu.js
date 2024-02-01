var currentUrl = null;

$(document).ready(function () {
  initialize_menu();

  $("#navigation").resizable({ handles: 'e, w', minWidth: 199, maxWidth: 500 });

  $("#menu-toggle").click(function () {
    $('#content').toggleClass('extended-panel');
    $("#navigation").toggle();
  });

  // On resize of the left side panel, resize the grid
  $("#navigation").bind("resize", function () {
    $("#content").css('left', $("#navigation").width() + 1);
    $("#navigation").css('height', 'auto');
  });

  History.Adapter.bind(window, 'statechange', function () {
    loadPageForHistoryState();
  });

  // Initial
  loadPageForHistoryState();
});

function loadPageForHistoryState() {
  var url = History.getState().url;
  if (url != currentUrl) {
    if (url === undefined) {
      $("#screen_content").empty();
      deselectMenuItems();
    } else {
      currentUrl = url;
      selectMenuItem(currentUrl);
      load_page(currentUrl);
    }
  }
}

function load_page(url) {
  // remove all the context-menu
  $("ul.context-menu").remove();

  $("#screen_content").empty();

  // Ekohe Add: Remove old columnpickers, tooltips when screen changes
  $('.wulin-columnpicker').remove();
  $('.material-tooltip').remove();
  cleanUpEditors();

  // Ekohe Edit: Use screen_content_loader as new indicator

  // var indicators = $("#activity #indicators");
  // indicators.html(gridManager.buildIndicatorHtml("init_menu", "Loading page..."));
  // indicators.find("#init_menu").show();

  $('<div />').attr('id', 'screen_content_loader_container')
    .append($('<div />').attr('id', 'screen_content_loader'))
    .prependTo($('#content'));

  $.ajax({
    type: 'GET',
    dataType: 'html',
    data: { xhr: 1 },
    url: url,
    success: function (html) {
      // Ekohe Edit: Use screen_content_loader defined in content view as new indicator
      // indicators.find("#init_menu_indicator").fadeOut();
      $('#screen_content_loader_container').remove();
      $("#screen_content").html(html);

      setTimeout(function () {
        trackGoogleAnalytics();

        let id = $("#screen_content > div").attr("id");
        $("#screen_content").removeClass();
        $("#screen_content").addClass(`content-${id}`);
      }, 250);
    },
    error: function () {
      // Ekohe Edit: Use screen_content_loader defined in content view as new indicator
      // indicators.find("#init_menu_indicator").fadeOut();
      $('#screen_content_loader_container').remove();
      // displayErrorMessage("An error occured while trying to load page. Please try again.");
    }
  });
}

function cleanUpEditors(id = false) {
  // we should cleanup open editors
  if (id) {
    $(".select-editor").data("id", id).remove();
    $(".textarea-wrapper").data("id", id).remove();
  } else {
    $(".select-editor").remove();
    $(".textarea-wrapper").remove();
  }
}

function trackGoogleAnalytics() {
  if (typeof (ga) != 'undefined') {
    ga('send', 'pageview', currentUrl);
  }
}

function deselectMenuItems() { $("#menu .active").removeClass("active"); }

function selectMenuItem(url) {
  rootUrl = History.getRootUrl(),
    relativeUrl = url.replace(rootUrl, '/');
  deselectMenuItems();
  $currentLink = $('#menu li.item a[href="' + relativeUrl + '"]');
  $currentLink.parent().addClass('active');
}

function initialize_menu() {
  // Click to load screen page
  $("#menu li.item a").on('click', function () {
    currentUrl = $(this).attr('href');

    // If the item in the menu is an absolute URL, then go to the change password page.
    if (/^https?:\/\//i.test(currentUrl)) {
      window.open(currentUrl);
      return;
    }

    if ($(this).hasClass('reverse')) {
      var currentWindowUrl = window.location.pathname + window.location.search;

      if (currentUrl == currentWindowUrl) {
        // go back to the original one
        currentUrl = $("a:not(.reverse)", $(this).parent()).attr('href');
      }
    }

    // State management
    History.pushState(null, document.title, currentUrl);

    return false;
  });

  // Click to toggle submenu
  $("#menu li.submenu a").click(function () {
    $(this).siblings("ul").toggle();
    return false;
  });

  $.fn.isInViewport = function() {
    const elementTop = $(this).offset().top;
    const elementBottom = elementTop + $(this).outerHeight();
    const viewportTop = $(window).scrollTop();
    const viewportBottom = viewportTop + $(window).height();
    return elementBottom > viewportTop && elementTop < viewportBottom;
  };

  // Focus on current active item
  $("#menu-toolbar li a#focus").click(function () {
    const menu = "#menu";
    const item = "#menu li.item.active";
    $(item).parent('ul').show();

    if (!$(item).isInViewport()) {
      $(menu).animate({
        scrollTop: $(item).offset().top
      }, 600);
    }
  });

  // Expand all submenu
  $("#menu-toolbar li a#expand").click(function () {
    $("#menu li.submenu ul").show();
  });

  // Collapse all submenu
  $("#menu-toolbar li a#collapse").click(function () {
    $("#menu li.submenu ul").hide();
  });

  // Click to go back to dashboard
  $("#navigation h1 a").click(function () {
    $("#menu .active").removeClass("active");
    // State management
    currentUrl = "/";
    History.pushState(null, document.title, currentUrl);
    load_page(currentUrl);
    return false;
  });
}
