// adjust toolbar style, set the toolbar left position and inner ul width
var dynamicToolbar = function(initial){
  var $headers = $(".grid-header");
  $headers.each(function(){
    var $header = $(this);
    var $toolbar_wrapper = $(this).find(".toolbar-wrapper");
    var $toolbar = $toolbar_wrapper.find(".toolbar");

    // get the current right visible item index before other operation
    var rightVisibleIndex = findEageItemsOnRight($toolbar_wrapper, $toolbar).visibleItemIndex;

    // set toolbar original left position
    var left = 0;
    $toolbar_wrapper.prevAll().each(function(){
      left += $(this).outerWidth() + parseFloat($(this).css("margin-left")) + parseFloat($(this).css("margin-right"));
    }) 
    left += 50;
    $toolbar_wrapper.css("left", left);

    if(initial) {
      // set inner toolbar fixed width
      var listWidth = 0;
      $toolbar.find("li").each(function(){
        listWidth += parseFloat($(this).outerWidth());
      });
      $toolbar.css('width', listWidth);
    }

    //if($toolbar_wrapper.width())
    adjustToolbarLeftPosition($toolbar_wrapper, $toolbar, rightVisibleIndex, initial);
  });
}

// Adjust the toolbar left position if the screen if not big enough
var adjustToolbarLeftPosition = function($toolbar_wrapper, $toolbar, rightVisibleIndex, initial){
  // adjust the toolbar left position if the most left item not fully displayed
  var oldLeft = parseFloat($toolbar_wrapper.css("left"));
  
  var smallEnough = false;
  var newLeft = oldLeft;
  var remainingWidth = $toolbar_wrapper.outerWidth();
  var remainingWidthClone = remainingWidth;

  // check small enough
  $($toolbar.find("li").get().reverse()).each(function(){
    remainingWidth -= $(this).outerWidth();
    var previousItemWidth = $(this).prev().outerWidth();
    if(remainingWidth < previousItemWidth) {
      smallEnough = true;
      return false;
    }
  });

  $($toolbar.find("li").get().slice(0, rightVisibleIndex).reverse()).each(function(){
    remainingWidthClone -= $(this).outerWidth();
    var previousItemWidth = $(this).prev().outerWidth();
    if(remainingWidthClone < previousItemWidth) {
      newLeft = oldLeft + remainingWidthClone;
      $toolbar_wrapper.css("left", newLeft);
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
    var prevLeft = newLeft - $toolbar_wrapper.siblings("span.tb_prev").outerWidth();
    $toolbar_wrapper.siblings("span.tb_prev").css("left", prevLeft);
    $toolbar_wrapper.siblings("span.tb_prev, span.tb_next").removeClass("hidden");
  }
}

// find the 2 items on the toolbar left eage (visible one and invisible one)
var findEageItemsOnLeft = function($toolbar_wrapper, $toolbar){
  var visibleItemWidth;
  var invisibleItemWidth;
  var visibleItemIndex = $toolbar.find(".toolbar_item").length;
  var mostLeft = true;
  var toolbarWrapperLeft = Math.round($toolbar_wrapper.offset().left);
  $($toolbar.find(".toolbar_item").get().reverse()).each(function(){
    var currentItemLeft = Math.round($(this).offset().left);
    if(currentItemLeft < toolbarWrapperLeft) {
      invisibleItemWidth = $(this).outerWidth();
      visibleItemWidth = $(this).next().outerWidth();
      mostLeft = false;
      return false;
    }
    visibleItemIndex--;
  });
  // if mostLeft
  if(mostLeft) {
    invisibleItemWidth = 0;
    visibleItemWidth = $toolbar.find(".toolbar_item").first().outerWidth();
  }
  return {mostLeft: mostLeft, visibleItemIndex: visibleItemIndex, visibleItemWidth: visibleItemWidth, invisibleItemWidth: invisibleItemWidth};
}

// find the 2 items on the toolbar right eage (visible one and invisible one)
var findEageItemsOnRight = function($toolbar_wrapper, $toolbar){
  var visibleItemWidth;
  var invisibleItemWidth;
  var visibleItemIndex = 0;
  var mostRight = true;
  var toolbarWrapperRight = Math.round($toolbar_wrapper.offset().left + $toolbar_wrapper.width());
  $toolbar.find(".toolbar_item").each(function(){
    var currentItemRight = Math.round($(this).offset().left + $(this).outerWidth());
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
      // $prev.siblings(".tb_next").removeClass("hidden");
      // if(leftResult.visibleItemIndex == 1) {
      //   $prev.addClass("hidden");
      // }
      adjustWrapperPositionAfterShift($toolbar_wrapper, leftPositionOffset);
    }); 
  }
});

// CLick the next button
$(".grid-header .tb_next").live('click', function(){
  var $next = $(this);
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
      // $next.siblings(".tb_prev").removeClass("hidden");
      // if(rightResult.visibleItemIndex == $toolbar.find(".toolbar_item").length - 1) {
      //   $next.addClass("hidden");
      // }
      adjustWrapperPositionAfterShift($toolbar_wrapper, leftPositionOffset);
    });
  }
});

// Resize window
$(window).resize(function(){
  dynamicToolbar(false);
});
