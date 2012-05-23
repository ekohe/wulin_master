// when editor validate return false

WulinMaster.behaviors.Validate = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onValidationError",

  subscribe: function(target) {
    var self = this;
    target[this.event].subscribe(function(e, args){ self.handler(args.validationResults) });
  },

  unsubscribe: function() {

  },

  handler: function(result) {
    if (result.msg) displayErrorMessage(result.msg);
  }

});

WulinMaster.BehaviorManager.register("validate", WulinMaster.behaviors.Validate);