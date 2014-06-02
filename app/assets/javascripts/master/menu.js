var currentUrl = null;

$(document).ready(function () {
  initialize_menu();

  $("#navigation").resizable({handles: 'e, w', minWidth:199, maxWidth:500});

  $("#navigation #nav_toggle").hover(function(){
    $(this).toggleClass("transparent");
  });

  $("#navigation #nav_toggle").toggle(function(){
    var $toggle = $(this);
    $("#navigation").animate({width:0});
    $('#content').animate({left:0}, function(){
      $toggle.toggleClass("open");
      $(window).trigger("resize");
    });
  },function(){
    var $toggle = $(this);
    $("#navigation").animate({width:199});
    $('#content').animate({left:200}, function(){
      $toggle.toggleClass("open");
      $(window).trigger("resize");
    });
  });
  
  // On resize of the left side panel, resize the grid
  $("#navigation").bind("resize", function(event, ui) {
    $("#content").css('left', $("#navigation").width()+1);
    $("#activity").css('width', $("#navigation").width());
    $("#user_nav").css('width', $("#navigation").width());
    $("#navigation").css('height', '100%');
  });
  
  $(window).bind('hashchange', function(e) { loadPageForBBQState(); });
  
  // Initial
  loadPageForBBQState();
});

function loadPageForBBQState() {
  var url = $.bbq.getState('url');
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
  $("#screen_content").empty();
  
  var indicators = $("#activity #indicators");
  // init grid loader
  indicators.html(gridManager.buildIndicatorHtml("init_menu", "Loading page..."));
  indicators.find("#init_menu").show();
  
  $.ajax({
    type: 'GET',
    dataType: 'html',
    url: url,
    success: function(html) {
      indicators.find("#init_menu_indicator").fadeOut();
      $("#screen_content").html(html);
      setTimeout(function() { trackGoogleAnalytics(); }, 250);
    },
    error: function() {
      indicators.find("#init_menu_indicator").fadeOut();
      // displayErrorMessage("An error occured while trying to load page. Please try again.");
    }
  });
}

function trackGoogleAnalytics() {
  if (typeof(ga)!='undefined') {
    ga('send', 'pageview', currentUrl);
  }
}

function deselectMenuItems() { $(".active").removeClass("active"); }

function selectMenuItem(url) {
  deselectMenuItems();
  var $currentLink = $('#menu li.item a[data-active-url*="' + url + '"]');
  if ($currentLink.size() === 0) {
    $currentLink = $('#menu li.item a[href="' + url + '"]');
  }
  $currentLink.parent().addClass('active');
}

function initialize_menu() {
  // Click to load screen page
  $("#menu li.item a").on('click', function() {
    $("#menu .active").removeClass("active");
    $(this).parent().addClass("active");
    // State management
    var state = {};
    currentUrl = $(this).attr('href');
    state['url'] = currentUrl;
    $.bbq.pushState(state);
    load_page(currentUrl);
    return false;
  });
  
  // Click to open submenu
  $("#menu li.submenu a").click(function() {
    $(this).find(".indicator").toggleClass("closed");
    $(this).siblings("ul").toggle();
    return false;
  });
  
  // Click to go back to dashboard
  $("#navigation h1 a").click(function() {
    $("#menu .active").removeClass("active");
    // State management
    var state = {};
    currentUrl = "/";
    state['url'] = currentUrl;
    $.bbq.pushState(state);
    load_page(currentUrl);
    return false;
  });
}
