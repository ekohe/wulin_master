var currentUrl = null;
var pinnedItemsCache = [];

$(document).ready(function() {
  initialize_menu();
  initializePinnedMenu();

  $("#navigation").resizable({ handles: 'e, w', minWidth: 199, maxWidth: 500 });

  $("#menu-toggle").click(function() {
    $('#content').toggleClass('extended-panel');
    $("#navigation").toggle();
  });

  // On resize of the left side panel, resize the grid
  $("#navigation").bind("resize", function() {
    $("#content").css('left', $("#navigation").width() + 1);
    $("#navigation").css('height', 'auto');
  });

  History.Adapter.bind(window, 'statechange', function() {
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
    success: function(html) {
      // Ekohe Edit: Use screen_content_loader defined in content view as new indicator
      // indicators.find("#init_menu_indicator").fadeOut();
      $('#screen_content_loader_container').remove();
      $("#screen_content").html(html);
      updateDocumentTitle();

      setTimeout(function() {
        trackGoogleAnalytics();

        let id = $("#screen_content > div").attr("id");
        $("#screen_content").removeClass();
        $("#screen_content").addClass(`content-${id}`);
      }, 250);
    },
    error: function() {
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

function urlPath(url) {
  var anchor = document.createElement("a");
  anchor.href = url;
  return anchor.pathname + anchor.search;
}

function appTitle() {
  if (window._appTitle) return window._appTitle;
  var parts = document.title.split(" | ");
  return parts.length > 1 ? parts[parts.length - 1] : document.title;
}

function menuTitleFromItem($item) {
  if (!$item.length) return "";
  var title = $item.data("title");
  if (title) return title;
  var $label = $item.find("a.waves-effect span, a:not(.reverse) span").first();
  if ($label.length) return $label.text().trim();
  return $item.find("a").first().text().trim();
}

function updateDocumentTitle() {
  var $activeItem = $("#menu li.item.active:visible").first();
  if (!$activeItem.length) $activeItem = $("#menu li.item.active").first();
  setDocumentTitleFromMenuItem($activeItem);
}

function updateDocumentTitleFromLink($link) {
  setDocumentTitleFromMenuItem($link.closest("li.item"));
}

function setDocumentTitleFromMenuItem($item) {
  var menuTitle = menuTitleFromItem($item);
  if (!menuTitle) return;
  document.title = menuTitle + " | " + appTitle();
}

function selectMenuItem(url) {
  var path = urlPath(url);
  deselectMenuItems();
  var $items = $("#menu li.item").filter(function() {
    if ($(this).attr("data-path") === path) return true;
    var href = $(this).find("a.waves-effect, a:not(.reverse)").first().attr("href");
    return href === path;
  });
  var $active = $items.filter(":visible").first();
  if (!$active.length) $active = $items.first();
  $active.addClass("active");
}

function initialize_menu() {
  // Click to load screen page
  $("#menu li.item a").on('click', function() {
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

    updateDocumentTitleFromLink($(this));

    // State management
    History.pushState(null, document.title, currentUrl);

    return false;
  });

  // Click to toggle submenu
  $("#menu li.submenu a").click(function() {
    $(this).siblings("ul").toggle();
    return false;
  });

  function elementRelativeToScrollArea(element, scrollArea) {
    const elementTop = $(element).offset().top;
    const elementBottom = elementTop + $(element).outerHeight();
    const scrollAreaTop = $(scrollArea).offset().top;
    const scrollAreaBottom = scrollAreaTop + $(scrollArea).outerHeight();

    return {
      onTop: elementTop < scrollAreaTop,
      onBottom: elementBottom > scrollAreaBottom
    };
  }

  // Focus on current active item
  $("#menu-toolbar li a#focus").click(function() {
    const menu = "#menu";
    const item = "#menu li.item.active";
    $(item).parent('ul').show();

    const itemPosition = elementRelativeToScrollArea(item, menu);

    if (itemPosition.onBottom) {
      $(menu).animate({
        scrollTop: $(item).offset().top - $(menu).offset().top
      }, 400);
    } else if (itemPosition.onTop) {
      $(menu).animate({
        scrollTop: $(menu).scrollTop() - ($(menu).offset().top - $(item).offset().top)
      }, 400);
    }
  });

  // Expand all submenu
  $("#menu-toolbar li a#expand").click(function() {
    $("#menu li.submenu ul").show();
  });

  // Collapse all submenu
  $("#menu-toolbar li a#collapse").click(function() {
    $("#menu li.submenu ul").hide();
  });

  // Click to go back to dashboard
  $("#navigation h1 a").click(function() {
    $("#menu .active").removeClass("active");
    document.title = appTitle();
    // State management
    currentUrl = "/";
    History.pushState(null, document.title, currentUrl);
    load_page(currentUrl);
    return false;
  });
}

function csrfToken() {
  return $('meta[name="csrf-token"]').attr('content');
}

function pinMenuItem(path) {
  var $menuItem = $('#menu li.item[data-path="' + path + '"]');
  if (!$menuItem.length) return;

  var pins = pinnedItemsCache.slice();
  pins.push({ path: path, title: $menuItem.data('title') });

  $.ajax({
    type: 'PUT',
    url: '/wulin_master/user_preferences/pinned_menus',
    headers: { 'X-CSRF-Token': csrfToken() },
    data: { value: JSON.stringify(pins) },
    dataType: 'json',
    success: function() { loadPinnedItems(); }
  });
}

function unpinMenuItem(path) {
  var pins = pinnedItemsCache.filter(function(item) { return item.path !== path; });

  if (pins.length === 0) {
    $.ajax({
      type: 'DELETE',
      url: '/wulin_master/user_preferences/pinned_menus',
      headers: { 'X-CSRF-Token': csrfToken() },
      dataType: 'json',
      success: function() { loadPinnedItems(); }
    });
  } else {
    $.ajax({
      type: 'PUT',
      url: '/wulin_master/user_preferences/pinned_menus',
      headers: { 'X-CSRF-Token': csrfToken() },
      data: { value: JSON.stringify(pins) },
      dataType: 'json',
      success: function() { loadPinnedItems(); }
    });
  }
}

function loadPinnedItems(callback) {
  $.ajax({
    type: 'GET',
    url: '/wulin_master/user_preferences/pinned_menus',
    dataType: 'json',
    success: function(items) {
      pinnedItemsCache = items || [];
      renderPinnedGroup();
      updatePinStates();
      if (currentUrl) selectMenuItem(currentUrl);
      if (callback) callback();
    }
  });
}

function renderPinnedGroup() {
  var $group = $('#pinned-group');
  var $list = $group.find('.pinned-items');
  $list.empty();

  if (pinnedItemsCache.length === 0) {
    $group.hide();
    return;
  }

  pinnedItemsCache.forEach(function(item) {
    var $original = $('#menu li.item[data-path="' + item.path + '"]');
    if (!$original.length) return;
    var icon = $original.data('icon') || 'crop_16_9';

    var $li = $('<li>', { class: 'item pinned-item', 'data-path': item.path, 'data-title': item.title });
    var $link = $('<a>', { href: item.path, class: 'waves-effect' })
      .append($('<i>', { class: 'material-icons' }).text(icon))
      .append($('<span>').text(item.title));
    var $unpin = $('<span>', { class: 'pin-toggle is-pinned', title: 'Unpin' });

    $li.append($link).append($unpin);
    var $reverse = $original.find('a.reverse');
    if ($reverse.length) $li.append($reverse.clone());
    $list.append($li);

    $link.on('click', function() {
      currentUrl = $(this).attr('href');
      updateDocumentTitleFromLink($(this));
      History.pushState(null, document.title, currentUrl);
      return false;
    });

    $unpin.on('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      unpinMenuItem(item.path);
    });
  });

  if ($list.children().length === 0) {
    $group.hide();
  } else {
    $group.show();
  }
}

function updatePinStates() {
  var pinnedPaths = pinnedItemsCache.map(function(item) { return item.path; });

  $('#menu li.item[data-path]').not('.pinned-item').each(function() {
    var path = $(this).data('path');
    if (pinnedPaths.indexOf(path) > -1) {
      $(this).hide();
    } else {
      $(this).show();
    }
  });

  $('#menu > ul > li.submenu').not('#pinned-group').each(function() {
    var $visible = $(this).find('li.item:visible');
    if ($visible.length === 0) {
      $(this).hide();
    } else {
      $(this).show();
    }
  });
}

function initializePinnedMenu() {
  loadPinnedItems();

  $('#menu').on('click', 'li.item[data-path]:not(.pinned-item) .pin-toggle', function(e) {
    e.preventDefault();
    e.stopPropagation();
    var path = $(this).closest('li.item').data('path');
    pinMenuItem(path);
  });
}
