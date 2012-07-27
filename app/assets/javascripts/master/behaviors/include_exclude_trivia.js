// Events for inclusion and exclusion grids:
// - 1. remove row highlight for opponent grid when select a row in current grid
// - 2. enable/disable 'Add' or 'Remove' button when select a row in the grid

WulinMaster.behaviors.IncludeExcludeTrivia = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onSelectedRowsChanged",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target[this.event].subscribe(function(){ self.handler() });
  },

  unsubscribe: function() {

  },

  handler: function() {
    var panel_buttons = $("#panel_inclusion_exclusion .panel_btns");
    var addButton = panel_buttons.find("#add_btn");
    var removeButton = panel_buttons.find("#remove_btn");
    var inclusionGridName = panel_buttons.data('inclusion-grid');
    var exclusionGridName = panel_buttons.data('exclusion-grid');
    var inclusionGrid = gridManager.getGrid(inclusionGridName);
    var exclusionGrid = gridManager.getGrid(exclusionGridName);

    if(this.grid.name == inclusionGridName && this.grid.getSelectedRows().length > 0) {
      addButton.attr('disabled', 'disabled');
      removeButton.removeAttr('disabled');
      exclusionGrid.resetActiveCell();   // remove highlight
    } else if(this.grid.name == exclusionGridName && this.grid.getSelectedRows().length > 0) {
      removeButton.attr('disabled', 'disabled');
      addButton.removeAttr('disabled');
      inclusionGrid.resetActiveCell();   // remove highlight
    } else if(inclusionGrid.getSelectedRows().length == 0 && exclusionGrid.getSelectedRows().length == 0) {
      addButton.attr('disabled', 'disabled');
      removeButton.attr('disabled', 'disabled');
    }
  }

});

WulinMaster.BehaviorManager.register("include_exclude_trivia", WulinMaster.behaviors.IncludeExcludeTrivia);