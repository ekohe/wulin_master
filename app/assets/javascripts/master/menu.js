var currentUrl = null;
var pinnedItemsCache = [];
var lastClickedMenuItem = null;

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
  // Prefer the copy the user clicked: an item can exist twice (original + shortcut),
  // and reverse URLs match no item's data-path at all
  var $active = $(lastClickedMenuItem);
  lastClickedMenuItem = null;
  if (!$active.closest("#menu").length) {
    var $items = $("#menu li.item").filter(function() {
      if ($(this).attr("data-path") === path) return true;
      var href = $(this).find("a.waves-effect, a:not(.reverse)").first().attr("href");
      return href === path;
    });
    if (!$items.length) return; // unknown URL (e.g. a reverse view): keep the current highlight
    $active = $items.filter(".active").first(); // keep the copy already highlighted
    if (!$active.length) $active = $items.filter(":visible").first();
    if (!$active.length) $active = $items.first();
  }
  deselectMenuItems();
  $active.addClass("active");
}

function initialize_menu() {
  // Click to load screen page (delegated: shortcut copies are rendered dynamically)
  $("#menu").on('click', 'li.item a', function() {
    var href = $(this).attr('href');

    // If the item in the menu is an absolute URL, then go to the change password page.
    if (/^https?:\/\//i.test(href)) {
      window.open(href);
      return false;
    }

    currentUrl = href;
    lastClickedMenuItem = $(this).closest('li.item')[0];
    var currentWindowUrl = window.location.pathname + window.location.search;

    if ($(this).hasClass('reverse') && currentUrl == currentWindowUrl) {
      // go back to the original one
      currentUrl = $("a:not(.reverse)", $(this).parent()).attr('href');
    }

    // Already on this screen (e.g. clicked the other copy of a pinned item):
    // just move the highlight, pushing an identical URL fires no statechange
    if (currentUrl == currentWindowUrl) {
      currentUrl = History.getState().url; // keep the format loadPageForHistoryState stores
      selectMenuItem(currentUrl);
      return false;
    }

    updateDocumentTitleFromLink($(this));

    // State management
    History.pushState(null, document.title, currentUrl);

    return false;
  });

  // Click to toggle submenu (header link only — "li.submenu a" would also
  // match item links and swallow their clicks before they bubble to #menu)
  $("#menu li.submenu > a").click(function() {
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
    if (currentUrl == window.location.pathname + window.location.search) {
      load_page(currentUrl); // pushing an identical URL fires no statechange
    } else {
      History.pushState(null, document.title, currentUrl); // statechange loads the page
    }
    return false;
  });
}

function csrfToken() {
  return $('meta[name="csrf-token"]').attr('content');
}

function pinMenuItem(path) {
  var $menuItem = $('#menu li.item[data-path="' + path + '"]');
  if (!$menuItem.length) return;
  if (pinnedItemsCache.some(function(item) { return item.path === path; })) return;

  var pins = pinnedItemsCache.slice();
  pins.push({ path: path, title: $menuItem.data('title') });
  savePinnedItems(pins);
}

function unpinMenuItem(path) {
  savePinnedItems(pinnedItemsCache.filter(function(item) { return item.path !== path; }));
}

function savePinnedItems(pins) {
  $.ajax({
    type: pins.length ? 'PUT' : 'DELETE',
    url: '/wulin_master/user_preferences/pinned_menus',
    headers: { 'X-CSRF-Token': csrfToken() },
    data: pins.length ? { value: JSON.stringify(pins) } : undefined,
    dataType: 'json',
    success: function() { applyPinnedItems(pins); }
  });
}

function loadPinnedItems() {
  $.ajax({
    type: 'GET',
    url: '/wulin_master/user_preferences/pinned_menus',
    dataType: 'json',
    success: applyPinnedItems
  });
}

function applyPinnedItems(items) {
  pinnedItemsCache = items || [];
  renderPinnedGroup();
  updatePinStates();
  if (currentUrl) selectMenuItem(currentUrl);
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
    var pinned = pinnedPaths.indexOf($(this).data('path')) > -1;
    $(this).find('.pin-toggle')
      .toggleClass('is-pinned', pinned)
      .attr('title', pinned ? 'Unpin' : 'Pin');
  });
}

function initializePinnedMenu() {
  loadPinnedItems();

  $('#menu').on('click', 'li.item[data-path] .pin-toggle', function(e) {
    e.preventDefault();
    e.stopPropagation();
    var path = $(this).closest('li.item').data('path');
    if ($(this).hasClass('is-pinned')) {
      unpinMenuItem(path);
    } else {
      pinMenuItem(path);
    }
  });
}
