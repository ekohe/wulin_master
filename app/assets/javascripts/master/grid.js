// Customized API to Slick.Grid

(function($) {
  // WulinMaster.Grid
  $.extend(true, window, {
    WulinMaster: {
      Grid: WulinMasterGrid
    }
  });

  //////////////////////////////////////////////////////////////////////////////////////////////
  // Customized API for WulinMaster

  function WulinMasterGrid(container, data, columns, options) {
    Slick.Grid.call(this, container, data, columns, options);

    var _self = this;

    // Ekohe Add: Customization of init()
    function wulinInit() {
      // Call SlickColumnPicker's init()
      _self.init()

      if (!_self.getOptions().explicitInitialization) {
        wulinFinishInitialization();
      }
    };

    function wulinFinishInitialization() {
      // set columnsById to {} for visibilty setting feature
      _self.setColumnsById({});
      // Remove invisible columns
      removeInvisibleColumns();
      // Call SlickColumnPicker's finishInitialization()
      _self.finishInitialization()
      // Use customized handler for dblclick
      _self.getCanvas().on("dblclick", wulinHandleDblClick)
    }

    // Ekohe Add: Customization of handleDblClick()
    //   1. Only work for editable column
    function wulinHandleDblClick(e) {
      var cell = _self.getActiveCell();

      // Call SlickColumnPicker's handleDblClick()
      _self.handleDblClick(e);

      // Ekohe Modify: Only work for editable column
      if(isColumnEditable(columns[cell.cell])) {
        _self.gotoCell(cell.row, cell.cell, true);
      }
    }

    //////////////////////////////////////////////////////////////////////////////////////////////
    // New API for WulinMaster

    // get the editable for a column accoring to self's config and current grid's config
    function isColumnEditable(column_option) {
      if(column_option.editable == undefined) {
        return options.editable;
      } else {
        return column_option.editable;
      }
    }

    // Remove columns which have option of visible:false when initialize the grid
    function removeInvisibleColumns() {
      var tmp = [];
      for (var i = 0; i < columns.length; i++) {
        if (columns[i].visible != false) {
          tmp.push(columns[i]);
        }
      }
      _self.setColumns(tmp);
    }

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
      this.trigger(this.onRendered, {});
    }

    $.extend(this, {
      // Events
      'onRendered':                     new Slick.Event(),
      'onCanvasResized':                new Slick.Event(),

      // methods
      'getRowByRecordId':               getRowByRecordId,
      'getSelectedIds':                 getSelectedIds,
      'resizeAndRender':                resizeAndRender,
      'initialRender':                  initialRender
    });

    wulinInit();
  }

  WulinMasterGrid.prototype = Object.create(Slick.Grid.prototype);
})(jQuery);
