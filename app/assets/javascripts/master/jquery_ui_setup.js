// jQuery UI Setup - This file ensures jQuery UI is globally available
import ui from 'jquery-ui'
import 'jquery-ui/ui/widgets/mouse'
import 'jquery-ui/ui/plugin'
import 'jquery-ui/ui/widget'
import 'jquery-ui/ui/widgets/resizable'
import 'jquery-ui/ui/widgets/sortable'

window.$.ui = ui

// Add keyCode constants that are missing from the jQuery UI import
if (!$.ui.keyCode) {
  $.ui.keyCode = {
    BACKSPACE: 8,
    COMMA: 188,
    DELETE: 46,
    DOWN: 40,
    END: 35,
    ENTER: 13,
    ESCAPE: 27,
    HOME: 36,
    LEFT: 37,
    PAGE_DOWN: 34,
    PAGE_UP: 33,
    PERIOD: 190,
    RIGHT: 39,
    SPACE: 32,
    TAB: 9,
    UP: 38
  };
}

// Ensure disableSelection is available on jQuery objects
if (!$.fn.disableSelection) {
  $.fn.disableSelection = function() {
    return this.bind( "selectstart.ui", function() {
      return false;
    });
  };
}
