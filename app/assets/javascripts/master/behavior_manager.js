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

    dispatchBehaviors: function(target, behaviors_config) {
      // try to find target's behaviors, and subsribe for target
      for(var i in behaviors_config) {
        var behavior = this.getBehavior(behaviors_config[i].name);
        if(behavior){
          $.extend(behavior, behaviors_config[i]);
          // if the behavior defined in the grid on a particular screen, or on all screen (no screens defined)
          if(behavior.screens == undefined || behavior.screens.indexOf(target.screen) >= 0){ 
            behavior.subscribe(target);
          }
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

