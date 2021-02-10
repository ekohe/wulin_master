// cell update events

WulinMaster.behaviors.Update = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onCellChange",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target[this.event].subscribe(function(e, args){ self.handler(args); });
  },

  unsubscribe: function() {

  },

  handler: function(args) {
    // memorize the updated item in local grid
    var updated_column;
    for(var i in args.item) {
      if(i !== 'id') updated_column = i;
    }

    // check the column has the target_model
    if (args.editCommand.editor.column.target_model) {
      this.updateTargetValue(args)
      return
    }

    // send update request
    Requests.updateByAjax(this.grid, args.item);
  },

  updateTargetValue: function(args) {
    try {
      // target model, example: position
      let model  = args.editCommand.editor.column.target_model

      // path for update the model
      let path   = args.editCommand.editor.column.target_path

      // model attribute
      let source = args.editCommand.editor.column.source

      if (model) {
        let self = this
        let data = args.item[model]
        let value = data[source]
        let id = data.id

        if (id > 0) {
          let item = {}
          item[source] = value

          $.ajax({
            type: "POST",
            dateType: 'json',
            url:  `/${path}/${id}.json`,
            data: {_method: 'PUT', item: item, authenticity_token: decodeURIComponent(window._token)},
            success: function(msg) {
              if(msg.success) {
                self.grid.loader.reloadData()
              } else {
                displayErrorMessage(msg.error_message);
                if(editCommand) {
                  editCommand.undo();
                } else {
                  self.grid.loader.reloadData();
                }
              }
            }
          })
        }
      }
    } catch (e) {
      console.log(e)
    }
  }

});

WulinMaster.BehaviorManager.register("update", WulinMaster.behaviors.Update);
