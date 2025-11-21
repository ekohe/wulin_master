WulinMaster.behaviors.ColorColumns = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  events: ['onAddExtraCellClasses'],

  subscribe: function (target) {
    this.grid = target;
    const [onAddExtraCellClasses] = this.events;
    target[onAddExtraCellClasses].subscribe((e, args) => this.setCellColor(args));
  },

  setCellColor: function ({ grid, row, cell, extraCellClasses }) {
    const cellColumnColor = grid.getColumns()[cell]['color'];
    if (cellColumnColor) {
      extraCellClasses.push('colored');
      extraCellClasses.push(`colored-${cellColumnColor}`);
    }
  },
});

WulinMaster.BehaviorManager.register('color_columns', WulinMaster.behaviors.ColorColumns);
