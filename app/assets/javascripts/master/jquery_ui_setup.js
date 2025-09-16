// jQuery UI Setup - This file ensures jQuery UI is globally available
import ui from 'jquery-ui'
import 'jquery-ui/ui/widgets/mouse'
import 'jquery-ui/ui/plugin'
import 'jquery-ui/ui/widget'
import 'jquery-ui/ui/widgets/resizable'
import 'jquery-ui/ui/widgets/sortable'

window.$.ui = ui

// Ensure disableSelection is available on jQuery objects
if (!$.fn.disableSelection) {
  $.fn.disableSelection = function() {
    return this.bind( "selectstart.ui", function() {
      return false;
    });
  };
}
