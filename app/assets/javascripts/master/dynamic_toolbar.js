// adjust toolbar style, set the toolbar left position and inner ul width
var dynamicToolbar = function(){
  var $headers = $(".grid-header");
  $headers.each(function(){
    var $header = $(this);
    var $toolbar_wrapper = $(this).find(".toolbar-wrapper");
    var $toolbar = $toolbar_wrapper.find(".toolbar");

    // set toolbar left position
    var left = $(this).find("h2").outerWidth() + 50;
    $toolbar_wrapper.css("left", left);

    // set inner toolbar fixed width
    var listWidth = 0;
    $toolbar.find("li").each(function(){
      listWidth += parseFloat($(this).outerWidth());
    });
    $toolbar.css('width', listWidth);

    //if($toolbar_wrapper.width())
    adjustToolbarLeftPosition($toolbar_wrapper, $toolbar);
  });
}

// Adjust the toolbar left position if the screen if not big enough
var adjustToolbarLeftPosition = function($toolbar_wrapper, $toolbar){
  // adjust the toolbar left position if the most left item not fully displayed
  var oldLeft = parseFloat($toolbar_wrapper.css("left"));
  var smallEnough = false;
  var newLeft = oldLeft;
  var remainingWidth = $toolbar_wrapper.width();
  var rightVisibleIndex = findEageItemsOnRight($toolbar_wrapper, $toolbar).visibleItemIndex;
  $($toolbar.find("li").get().slice(0, rightVisibleIndex+1).reverse()).each(function(){
    remainingWidth -= $(this).outerWidth();
    var previousItemWidth = $(this).prev().outerWidth();
    if(remainingWidth < previousItemWidth) {
      newLeft = oldLeft + remainingWidth;
      $toolbar_wrapper.css("left", newLeft);
      smallEnough = true;
      return false;
    }
  });
  // hide prev and next button when window is wider enough, otherwise show them
  if(!smallEnough) {
    $toolbar_wrapper.siblings("span.tb_prev, span.tb_next").addClass("hidden");
    // also, show all items
    $toolbar_wrapper.find(".toolbar").css("left", 0);
  } else {
    // make sure the first toolbar item always align left or more of toolbar_wrapper (otherwise there is a blank between first item and prev button)
    if($toolbar.offset().left > $toolbar_wrapper.offset().left) {
      $toolbar.css("left", 0);
    }
    var prevLeft = newLeft - 15;  // 15 is the prev button width, need to refactor
    $toolbar_wrapper.siblings("span.tb_prev").css("left", prevLeft);
    $toolbar_wrapper.siblings("span.tb_prev, span.tb_next").removeClass("hidden");
  }
}

// find the 2 items on the toolbar left eage (visible one and invisible one)
var findEageItemsOnLeft = function($toolbar_wrapper, $toolbar){
  var visibleItemWidth;
  var invisibleItemWidth;
  var mostLeft = true;
  var toolbarWrapperLeft = $toolbar_wrapper.offset().left;
  $($toolbar.find(".toolbar_item").get().reverse()).each(function(){
    var currentItemLeft = $(this).offset().left;
    if(currentItemLeft < toolbarWrapperLeft) {
      invisibleItemWidth = $(this).outerWidth();
      visibleItemWidth = $(this).next().outerWidth();
      mostLeft = false;
      return false;
    }
  });
  // if mostLeft
  if(mostLeft) {
    invisibleItemWidth = 0;
    visibleItemWidth = $toolbar.find(".toolbar_item").first().outerWidth();
  }
  return {mostLeft: mostLeft, visibleItemWidth: visibleItemWidth, invisibleItemWidth: invisibleItemWidth};
}

// find the 2 items on the toolbar right eage (visible one and invisible one)
var findEageItemsOnRight = function($toolbar_wrapper, $toolbar){
  var visibleItemWidth;
  var invisibleItemWidth;
  var visibleItemIndex = 0;
  var mostRight = true;
  var toolbarWrapperRight = $toolbar_wrapper.offset().left + $toolbar_wrapper.width();
  $toolbar.find(".toolbar_item").each(function(){
    var currentItemRight = $(this).offset().left + $(this).outerWidth();
    if(currentItemRight > toolbarWrapperRight) {
      invisibleItemWidth = $(this).outerWidth();
      visibleItemWidth = $(this).prev().outerWidth();
      mostRight = false;
      return false;
    }
    visibleItemIndex++;
  });
  // if mostRight
  if(mostRight) {
    invisibleItemWidth = 0;
    visibleItemWidth = $toolbar.find(".toolbar_item").last().outerWidth();
  }
  return {mostRight: mostRight, visibleItemIndex: visibleItemIndex, visibleItemWidth: visibleItemWidth, invisibleItemWidth: invisibleItemWidth};
}

// After clicking prev or next, if the widths of item appeared and disappeared are different, should adjust the left position of toolbar wrapper 
var adjustWrapperPositionAfterShift = function($toolbar_wrapper, offset){
  var $prev = $toolbar_wrapper.siblings(".tb_prev");
  var newWrapperLeft = parseFloat($toolbar_wrapper.css("left")) + offset;
  var newPrevLeft = parseFloat($prev.css("left")) + offset;
  $toolbar_wrapper.css("left", newWrapperLeft);
  $prev.css("left", newPrevLeft);
}

// Click the prev button
$(".grid-header .tb_prev").live('click', function(){
  var $prev = $(this);
  var $toolbar_wrapper = $(this).siblings(".toolbar-wrapper");
  var $toolbar = $toolbar_wrapper.find(".toolbar");

  var leftResult = findEageItemsOnLeft($toolbar_wrapper, $toolbar);
  var rightResult = findEageItemsOnRight($toolbar_wrapper, $toolbar);

  var mostLeft = leftResult.mostLeft;
  var shiftWidth = rightResult.visibleItemWidth;
  var leftPositionOffset = shiftWidth - leftResult.invisibleItemWidth

  // If not reach the left eage, continue shift
  if(!mostLeft){
    $toolbar.animate({
      left: '+=' + shiftWidth
    }, 'slow', function(){
      adjustWrapperPositionAfterShift($toolbar_wrapper, leftPositionOffset);
    }); 
  }
});

// CLick the next button
$(".grid-header .tb_next").live('click', function(){
  var $toolbar_wrapper = $(this).siblings(".toolbar-wrapper");
  var $toolbar = $toolbar_wrapper.find(".toolbar");

  var leftResult = findEageItemsOnLeft($toolbar_wrapper, $toolbar);
  var rightResult = findEageItemsOnRight($toolbar_wrapper, $toolbar);

  var mostRight = rightResult.mostRight;
  var shiftWidth = rightResult.invisibleItemWidth;
  var leftPositionOffset = leftResult.visibleItemWidth - shiftWidth;

  // If not reach the right eager, continue shift
  if(!mostRight) {
    $toolbar.animate({
      left: '-=' + shiftWidth
    }, 'slow', function(){
      adjustWrapperPositionAfterShift($toolbar_wrapper, leftPositionOffset);
    });
  }
});

// Resize window
$(window).resize(function(){
  dynamicToolbar();
});
