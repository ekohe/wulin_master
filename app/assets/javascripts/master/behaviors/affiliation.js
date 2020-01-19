// master-detail grid relation, detail grid render the records which belongs to the selected row of master grid

WulinMaster.behaviors.Affiliation = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onSelectedRowsChanged",

  subscribe: function(target) {
    var self = this;

    this.detail_grids = this.detail_grids || [];
    if(this.detail_grids.indexOf(target) < 0) {
      this.detail_grids.push(target);
    }

    this.master_grid = gridManager.getGrid(self.master_grid_name);
    if(this.master_grid) {
      this.master_grid[this.event].subscribe(function(){ self.handler(); });
    }
  },

  unsubscribe: function() {

  },

  handler: function() {
    // get the selected id, then filter the detail grid
    var masterIds = this.master_grid.getSelectedIds();
    if (masterIds.length != 1) return false;

    var association_key = this.through;
    for(var i=0; i < this.detail_grids.length; i++) {
      var detailGrid = this.detail_grids[i];
      // save the master relation info into detail grid
      detailGrid.master = {filter_column: association_key, filter_value: masterIds[0], filter_operator: this.operator};
      detailGrid.master_grid = this.master_grid;
      // apply sorting state if has
      var sortingStates = detailGrid.states["sort"];
      if(sortingStates) {
        detailGrid.loader.setSortWithoutRefresh(sortingStates["sortCol"], sortingStates["sortDir"]);
      }
      // filter the detail grid
      detailGrid.resetActiveCell();

      var existingFilters = $.map(detailGrid.loader.getFilters(), function(e) { return e[0]; });
      var candidateFilters = detailGrid.candidateFilters;
      var dif = $.difference(existingFilters, candidateFilters);
      // if current filters cover  candidate filters
      // or current filters equals candidate filters
      // or the current filter is the last candidate filter,
      // add it and reload the grid,
      // otherwise don't reload the grid
      if(existingFilters.length > candidateFilters.length || dif.length === 0 || dif.length === 1 && dif[0] == association_key) {
        detailGrid.loader.addFilter(association_key, masterIds[0], this.operator);
      } else {
        detailGrid.loader.addFilterWithoutRefresh(association_key, masterIds[0], this.operator);
      }

      var default_color = 'teal';
      // Set master grid's style for selection
      var selectionColor = 'grid-selection-color-' + (this.master_grid.options['selectionColor'] || default_color);
      this.master_grid.container.addClass(selectionColor);

      // Set detail grid's style
      var colorTheme = 'grid-color-' + (detailGrid.options['colorTheme'] || default_color);
      detailGrid.container.addClass('detail-grid').addClass(colorTheme);
      var bgColor = 'grid-bg-color-' + (detailGrid.options['bgColor'] || default_color);
      detailGrid.container.addClass(bgColor);
      detailGrid.container.find('.grid-header').removeClass('has-selected-rows');

      // Set detail grid's title
      var $detailGridTitle = detailGrid.container.find('.grid-header h2');
      $detailGridTitle.html(
        this.master_grid.title + ' #' + masterIds[0] +
        ' > <span class="detail-grid-title">' +
        detailGrid.title + '</span>'
      );
    }
  },

  shadeRGBColor: function (color, percent) {
    var f=color.split(","),t=percent<0?0:255,p=percent<0?percent*-1:percent,R=parseInt(f[0].slice(4)),G=parseInt(f[1]),B=parseInt(f[2]);
    return "rgb("+(Math.round((t-R)*p)+R)+","+(Math.round((t-G)*p)+G)+","+(Math.round((t-B)*p)+B)+")";
  }

});

WulinMaster.BehaviorManager.register("affiliation", WulinMaster.behaviors.Affiliation);
