// Customized API to Slick.RowSelectionModel

(function($) {
  // WulinMaster.RowSelectionModel
  $.extend(true, window, {
    WulinMaster: {
      RowSelectionModel: RowSelectionModel
    }
  });

  //////////////////////////////////////////////////////////////////////////////////////////////
  // Customized API for WulinMaster

  function RowSelectionModel(options) {
    Slick.RowSelectionModel.call(this, options);

    var _self = this;

    $.extend(this, {
    });
  }

  RowSelectionModel.prototype = Object.create(Slick.RowSelectionModel.prototype);
})(jQuery);
