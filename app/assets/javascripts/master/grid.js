// Customized API to Slick.Grid

(function($) {
  // WulinMaster.Grid
  $.extend(true, window, {
    WulinMaster: {
      Grid: WulinMasterGrid
    }
  });

  function WulinMasterGrid(container, data, columns, options) {
    Slick.Grid.call(this, container, data, columns, options);

    //////////////////////////////////////////////////////////////////////////////////////////////
    // General

    // Same logic to trigger() in slick.grid.js, recreate here because SlickGrid
    // doesn't open it to outsides
    function trigger(evt, args, e) {
      e = e || new Slick.EventData();
      args = args || {};
      args.grid = self;
      return evt.notify(args, e, self);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////
    // Customized API for WulinMaster

    function getRowByRecordId(id) {
      var data = this.getData();
      if (data.length == 0 || data.length > 0 && !data[0]) {
        if (self.loader) data = self.loader.oldData;
      }
      for(var i in data) {
        if (data.hasOwnProperty(i) && i !== 'length' && data[i] && data[i].id == id) { return { row: this.getActiveCell.row, index: i}; };
      }
    }

    function getSelectedIds() {
      try {
        var selectedIndexes = this.getSelectedRows();
        var ids;
        if (selectedIndexes.length > 0) {
          ids = $.map(selectedIndexes,function(n, i) {
            return this.getDataItem(n)['id'];
          }.bind(this));
          return ids;
        } else {
          return [];
        }
      } catch (e) {
        alert('You selected too many rows! Please select again.');
      }
    }

    function resizeAndRender() {
      if (options.forceFitColumns) {
        this.autosizeColumns();
      } else {
        this.resizeCanvas();
      }
    }

    function initialRender() {
      this.resizeAndRender();
      trigger(this.onRendered, {});
    }

    $.extend(this, {
      // Events
      'onRendered':                     new Slick.Event(),

      // methods
      'getRowByRecordId':               getRowByRecordId,
      'getSelectedIds':                 getSelectedIds,
      'resizeAndRender':                resizeAndRender,
      'initialRender':                  initialRender
    });
  }

  WulinMasterGrid.prototype = Object.create(Slick.Grid.prototype);
})(jQuery);
