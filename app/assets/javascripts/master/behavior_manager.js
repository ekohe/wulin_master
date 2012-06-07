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
      return behaviors[b_name];
    },

    dispatchBehaviors: function(target, behavior_names) {
      // try to find target's behaviors, and subsribe for target
      for(var i in behavior_names) {
        var behavior = this.getBehavior(behavior_names[i]);
        if(behavior){
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

