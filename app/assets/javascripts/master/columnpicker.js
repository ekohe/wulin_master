// Customized API to Slick.Controls.ColumnPicker

(function($) {
  // WulinMaster.ColumnPicker
  $.extend(true, window, {
    WulinMaster: {
      ColumnPicker: WulinMasterColumnPicker
    }
  });

  //////////////////////////////////////////////////////////////////////////////////////////////
  // Customized API for WulinMaster

  function WulinMasterColumnPicker(columns, grid, options) {
    Slick.Controls.ColumnPicker.call(this, columns, grid, options);

    var _self = this;

    // Ekohe Add: Customization of init()
    function wulinInit() {
      // Call SlickColumnPicker's init()
      _self.init()

      // Subscribe customized handleHeaderContextMenu() to onHeaderContextMenu event
      grid.onHeaderContextMenu.subscribe(wulinHandleHeaderContextMenu);

      // Rewrite menu.click to use customized updateColumn()
      _self.getMenu().on("click", wulinUpdateColumn);

      // Bind the column pick event
      _self.getMenu().on("click", handleColumnPick);
      bindGrid();
    }

    // Ekohe Add: Notify onColumnsPick event
    function handleColumnPick(e, args) {
      _self.onColumnsPick.notify({});
    }

    // Ekohe Add: Assign the picker itself to grid
    function bindGrid() {
      grid.picker = _self;
    }

    // Ekohe Modify: Customization of destroy()
    function destroy() {
      // Ekohe Modify: Use customized wulinHandleHeaderContextMenu()
      grid.onHeaderContextMenu.unsubscribe(wulinHandleHeaderContextMenu);

      grid.onColumnsReordered.unsubscribe(_self.updateColumnOrder());
      _self.getMenu().remove();
    }

    // Ekohe Add: Customization of handleHeaderContextMenu()
    //   1. Add "All/None" checkbox
    //   2. Use attr instead of data for columns checkbox
    //   3. Add processing for "All/None" checkbox in columns checkbox
    function wulinHandleHeaderContextMenu(e, args) {
      // Call SlickColumnPicker's handleHeaderContextMenu()
      _self.handleHeaderContextMenu(e, args)

      var $li, $allNoneInput;
      var $menu = _self.getMenu();
      var columnCheckboxes = _self.getColumnCheckboxes();

      // Prepend "All/None" checkbox to menu
      $("<hr/>").prependTo($menu);
      $li = $("<li />").prependTo($menu);
      $allNoneInput = $("<input type='checkbox' id='all_none' checked='checked' />").appendTo($li);
      $("<label for='all_none'>All/None</label>").appendTo($li);

      // Add customized attr and handling allNoneInput to columns checkbox
      $.each(columnCheckboxes, function (i, e) {
        $(this).attr({id: "columnpicker_" + i, name: columns[i].field})
        if (grid.getColumnIndex(columns[i].id) == null) {
          $allNoneInput.removeAttr("checked");
        }
      });
    }

    // Ekohe Add: Customization of updateColumn()
    //   1. Add "All/None" checkbox hanlder
    function wulinUpdateColumn(e) {
      // Call SlickColumnPicker's updateColumn()
      _self.updateColumn(e);

      // Ekohe Add: "All/None" checkbox hanlder
      var $menu = _self.getMenu();
      if (e.target.id == 'all_none') {
        if (e.target.checked) {
          $menu.find(":checkbox[id^=columnpicker]").attr('checked', 'checked');
          grid.setColumns(columns);
        } else {
          $menu.find(":checkbox[id^=columnpicker]").not("[name='id']").removeAttr('checked');
          var idColumns = $.grep(grid.getColumns(), function(n, i){
            return (n.field == 'id');
          });
          grid.setColumns(idColumns);
        }
        return;
      }
    }

    // Ekohe Add
    $.extend(this, {
      // Events
      "onColumnsPick": new Slick.Event(),

      // Methods
      "destroy": destroy
    });

    // Ekohe Add: Call customized initialization
    wulinInit();
  }

  WulinMasterColumnPicker.prototype = Object.create(Slick.Controls.ColumnPicker.prototype);
})(jQuery);
