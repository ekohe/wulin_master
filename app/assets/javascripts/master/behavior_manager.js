$.namespace('WulinMaster.BehaviorManager');
$.namespace('WulinMaster.behaviors');

// behavior manager
WulinMaster.BehaviorManager = function(){
  var behaviors = {};

  return {
    register: function(b_name, b_obj) {
      //console.log(b_name + " registered!")
      behaviors[b_name] = b_obj;
    },

    unregister: function(b_name) {
      delete behaviors[b_name];
    },

    getBehavior: function(b_name) {
      var behavior_proto = behaviors[b_name];
      // extend the behavior prototype to create a new behavior, avoid the same behavior conflict in one screen
      return $.extend({}, behavior_proto);
    },

    dispatchBehaviors: function(target, behavior_configs) {
      // try to find target's behaviors, and subsribe for target
      for(var i=0;i < behavior_configs.length; i++) {
        var behavior = this.getBehavior(behavior_configs[i].name);
        if(behavior){
          $.extend(behavior, behavior_configs[i]);
          behavior.subscribe(target);
        }
      }
    }
  };
}();

// base behavior
WulinMaster.behaviors.BaseBehavior = {
  _isBehavior: true,
  
  subscribe : $.noop,
  unsubscribe : $.noop
}

