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

    this.getRowByRecordId = function getRowByRecordId(id) {
      var data = this.getData();
      if(data.length == 0 || data.length > 0 && !data[0]) data = self.loader.oldData;
      for(var i in data) {
        if (data.hasOwnProperty(i) && i !== 'length' && data[i] && data[i].id == id) { return { row: this.getActiveCell.row, index: i}; };
      }
    }

    this.getSelectedIds = function getSelectedIds() {
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
  }

  WulinMasterGrid.prototype = Object.create(Slick.Grid.prototype);
})(jQuery);
