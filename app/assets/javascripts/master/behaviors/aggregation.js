WulinMaster.behaviors.Aggregation = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  events: ['onRendered', 'onDataLoaded'],

  subscribe: function (target) {
    this.grid = target;
    const [onRendered, onDataLoaded] = this.events;
    target[onRendered].subscribe((_, args) => this.renderSpan(args));
    target.loader[onDataLoaded].subscribe((_, args) => this.fillSpan(args));
  },

  utils: function () {
    const getPager = grid => $('.pager-item.extra', grid.container);
    const addAggregationSpan = $pager => $("<span/>").attr('id', 'aggregation').appendTo($pager);
    const getSpan = grid => $('span#aggregation', grid.container);
    return {
      getPager, addAggregationSpan, getSpan,
    };
  },

  renderSpan: function (args) {
    const {grid} = this;
    const {getPager, addAggregationSpan} = this.utils();
    return addAggregationSpan(getPager(grid));
  },

  fillSpan: async function (args) {
    const {grid} = this;
    const {getSpan} = this.utils();
    const aggregation = grid.loader.getPagingInfo()['aggregation'] || '';
    const $span = getSpan(grid);
    $span.text(aggregation);
  },
});

WulinMaster.BehaviorManager.register('aggregation', WulinMaster.behaviors.Aggregation);
