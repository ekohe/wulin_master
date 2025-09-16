// Import jQuery setup FIRST to ensure global availability
import './jquery_setup.js'

// Import jQuery UI setup to ensure global availability
import './jquery_ui_setup.js'

// External dependencies
import 'rails-ujs'
import 'materialize-css'

$(function(){
  if (navigator.userAgent.indexOf('AppleWebKit') === -1 && navigator.userAgent.indexOf('Gecko') === -1) {
    displayNewNotification('The browser you are currently using is not supported, we recommend using Chrome.', true);
  }
});

// jQuery plugins
import '../jquery_plugins/date.format.js'
import '../jquery_plugins/flatpickr.js'
import '../jquery_plugins/jquery.form.js'
import '../jquery_plugins/jquery.history.js'
import '../jquery_plugins/jquery.inputmask.bundle.js'
import '../jquery_plugins/jquery.namespace.js'
import '../jquery_plugins/lazyjsonviewer.js'
import '../jquery_plugins/materialnote.js'
import '../jquery_plugins/select2.js'
import '../jquery_plugins/sortable.js'
window.Sortable = Sortable;

// SlickGrid dependencies
import '../jquery_plugins/SlickGrid/lib/chosen.jquery.js'
import '../jquery_plugins/SlickGrid/lib/extension.js'
import '../jquery_plugins/SlickGrid/lib/jquery.event.drag-2.2.js'
import '../jquery_plugins/SlickGrid/slick.core.js'
import '../jquery_plugins/SlickGrid/slick.grid.js'
import '../jquery_plugins/SlickGrid/controls/slick.columnpicker.js'
import '../jquery_plugins/SlickGrid/controls/slick.pager.js'
import '../jquery_plugins/SlickGrid/plugins/slick.autotooltips.js'
import '../jquery_plugins/SlickGrid/plugins/slick.cellcopymanager.js'
import '../jquery_plugins/SlickGrid/plugins/slick.cellrangedecorator.js'
import '../jquery_plugins/SlickGrid/plugins/slick.cellrangeselector.js'
import '../jquery_plugins/SlickGrid/plugins/slick.cellselectionmodel.js'
import '../jquery_plugins/SlickGrid/plugins/slick.checkboxselectcolumn.js'
import '../jquery_plugins/SlickGrid/plugins/slick.rowdetailview.js'
import '../jquery_plugins/SlickGrid/plugins/slick.rowselectionmodel.js'

// Settings
import '../setting/setting.js'

// Overrides
import '../overrides/chosen.jquery.js'
import '../overrides/jquery_difference.js'

// Core master files (in dependency order)
import './escape_html.js'
import './utility.js'
import './datetime.js'
import './notifications.js'
import './wulin_form.js'
import './ajax_error_handler.js'
import './connectionmanager.js'
import './dialog.js'
import './editors.js'
import './filterpanel.js'
import './formatters.js'
import './grid_requests.js'
import './grid_states_manager.js'
import './loader.js'
import './materialize_auto_init.js'
import './menu.js'
import './panel.js'
import './remotemodel.js'
import './row_detail_templates.js'
import './ui_helper.js'
import './grid_manager.js'

// SlickGrid extensions (contains deep_clone function)
import '../jquery_plugins/SlickGrid/lib/extension.js'

// Managers
import './behavior_manager.js'
import './action_manager.js'

// Wulin Master Behaviors
import './behaviors/add_candidate_filter.js'
import './behaviors/affiliation.js'
import './behaviors/aggregation.js'
import './behaviors/clear_detail_when_multi_select.js'
import './behaviors/clear_filters.js'
import './behaviors/color_columns.js'
import './behaviors/column_filter.js'
import './behaviors/disable_sorting_initially.js'
import './behaviors/disable_toolbar_initially.js'
import './behaviors/empty_detail.js'
import './behaviors/enable_sorting_after_loading.js'
import './behaviors/enable_toolbar_after_loading.js'
import './behaviors/get_operate_ids.js'
import './behaviors/highlight.js'
import './behaviors/include_exclude_trivia.js'
import './behaviors/update.js'
import './behaviors/validate.js'

// Wulin Master Actions
import './actions/add_detail.js'
import './actions/copy_grid_states.js'
import './actions/create.js'
import './actions/delete.js'
import './actions/detail_add.js'
import './actions/dynamic_edit.js'
import './actions/edit.js'
import './actions/export_role_permission.js'
import './actions/filter_default_grid_states.js'
import './actions/filter.js'
import './actions/fullscreen.js'
import './actions/hotkey_create.js'
import './actions/hotkey_delete.js'
import './actions/import_role_permission.js'
import './actions/json_view.js'
import './actions/make_default_grid.js'
import './actions/multiple_grid_states.js'
import './actions/show_all.js'
import './actions/switch.js'

// Dropzone
import '../dropzone.min.js'

window.__globalWillAppend = false

// Expose deep_clone globally for backward compatibility
// The deep_clone function is defined in extension.js but needs to be globally accessible
window.deep_clone = window.deep_clone || function(myObj){
  if(typeof(myObj) != 'object' || myObj instanceof Array) return myObj;
  if(myObj == null) return myObj;

  var myNewObj = new Object();

  for(var i in myObj)
     myNewObj[i] = window.deep_clone(myObj[i]);

  return myNewObj;
};
