// master-detail relation (when multiple masters - one detail), add candidate filters as a grid attribute,
// before doing grid.loader.addFitler, we should check the existing filters and candidate filters,
// if exsiting filters less than candidate filters (except the current filter), should not referesh the grid,
// until the current filter is the last candidate filter, we can refresh the grid
// code example see Affilication behavior

WulinMaster.behaviors.AddCandidateFilter = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onRendered",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target[this.event].subscribe(function(){ self.handler(); });
  },

  unsubscribe: function() {

  },

  handler: function() {
    if(!this.grid.candidateFilters) {
      this.grid.candidateFilters = [this.filter];
    } else if(this.grid.candidateFilters.indexOf(this.filter) < 0) {
      this.grid.candidateFilters.push(this.filter);
    }
  }

});

WulinMaster.BehaviorManager.register("add_candidate_filter", WulinMaster.behaviors.AddCandidateFilter);