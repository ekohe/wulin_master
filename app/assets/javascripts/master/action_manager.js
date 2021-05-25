$.namespace('WulinMaster.ActionManager');
$.namespace('WulinMaster.actions');

// action manager
WulinMaster.ActionManager = function(){
  var actions = {};

  return {
    register: function(a_obj) {
      actions[a_obj.name] = a_obj;
    },

    unregister: function(a_obj) {
      delete actions[a_obj.name];
    },

    getAction: function(a_name) {
      var action_proto = actions[a_name];
      return $.extend({}, action_proto);
    },

    dispatchActions: function(target, action_configs) {
      // try to find target's behaviors, and subsribe for target
      for(var i in action_configs) {
        var action = this.getAction(action_configs[i].name);
        if(action){
          $.extend(action, action_configs[i]);
          $.extend(action, {target: target});
          if(action.init) action.init();
        }
      }
    }
  };
}();


// we assume the wulin_master action is a click event on toolbar item, but you can override to satisfy your requirement
WulinMaster.actions.BaseAction = {
  _isAction: true,
  name: null,
  event: "click",
  triggerElementIdentifier: null,
  target: null,

  // in most case, don't need to override
  init : function() {
    // get the trigger element, you can override triggerElementIdentifier
    this.triggerElement = $("#content").find(this.triggerElementIdentifier);
    if(this.triggerElement.length === 0){
      this.triggerElement = $("#" + this.name + "_action_on_" + this.target.name);
    }

    // activate the action
    this.activate();
  },

  // get the grid
  getGrid: function(){
    if(this.target) {
      this.grid = this.target;
    } else {
      var grid_name = this.triggerElement.closest(".toolbar").data("grid");
      this.grid = gridManager.getGrid(grid_name);
    }
    return this.grid;
  },

  // can be overrided
  activate: function(){
    var self = this;
    this.triggerElement.off(self.event).on(self.event, function(e, args){
      if($(this).hasClass('toolbar_icon_disabled')) return false;
      self.handler(e, args);
    });
  },

  // Handle delete confirm with dialog
  deleteGridRecords: function(grid, ids) {
    var self = this;
    $('#confirm-modal').modal('open');
    $('#confirmed-btn').off('click').on('click', function() {
      Requests.deleteByAjax(grid, ids);
      $('#confirm-modal').modal('close');
      ids = [];
      // reload the master grid (for dettach detail action)
      if(self.reload_master && grid.master_grid) {
        grid.master_grid.loader.reloadData();
      }
    })
  },

  // Set height for grid related elements in Modal
  setGridHeightInModal: function(modalDom) {
    var gridCanvasHeight = modalDom.height() -
                           modalDom.find('.modal-header').outerHeight() -
                           modalDom.find('.modal-content .grid-header').outerHeight() -
                           modalDom.find('.modal-content .slick-header').outerHeight() -
                           modalDom.find('.modal-footer').outerHeight() -
                           modalDom.find('.modal-content .extra-block').outerHeight -
                           modalDom.find('.pager').outerHeight();
    modalDom.find('.modal-content .slick-viewport').height(gridCanvasHeight + 'px');
    modalDom.find('.modal-content .grid-canvas').height('auto');
    modalDom.find('.modal-content .grid').height('auto');
  },

  // override this to define what the action to do
  handler: $.noop
};
