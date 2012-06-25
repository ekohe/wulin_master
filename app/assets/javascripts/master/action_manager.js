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

    dispatchActions: function(target, action_names) {
      // try to find target's behaviors, and subsribe for target
      for(var i in action_names) {
        var action = this.getAction(action_names[i]);
        if(action){
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
    if(this.triggerElement.length == 0){
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
      self.handler(e, args);
    })
  },

  // override this to define what the action to do
  handler: $.noop
}


