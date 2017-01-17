# Customization of SlickGrid

## Customization of `slick.grid.js`

### Design Pattern & Preparation in `SlickGrid()`

##### Create `WulinMasterGrid()` to inherit `SlickGrid()`

`master/grid.js`
``` js
(function($) {
  $.extend(true, window, {
    WulinMaster: {
      Grid: WulinMasterGrid
    }
  });

  function WulinMasterGrid(container, data, columns, options) {
    Slick.Grid.call(this, container, data, columns, options);

    var _self = this;

    // Customization ...
  }

  WulinMasterGrid.prototype = Object.create(Slick.Grid.prototype);
})(jQuery);
```

##### Add new `getter`/`setter`s to `SlickGrid()`

`jquery_plugins/SlickGrid/slick.grid.js`
``` js
function SlickGrid(container, data, columns, options) {
  ...

  //////////////////////////////////////////////////////////////////////////////////////////////
  // Ekohe Add: Getters/Setters

  function getRows() {
    return rowsCache;
  }

  function setColumnsById(c){
    columnsById = c;
  }
  ...
}
```

##### Expose new APIs in `SlickGrid()`

`jquery_plugins/SlickGrid/slick.grid.js`
``` js
function SlickGrid(container, data, columns, options) {
  ...

  $.extend(this, {
    ...

    // Ekohe Add: New APIs
    "getRows": getRows,
    "getRowAt": getRowAt,
    "getCanvas": getCanvas,
    "getSerializedEditorValue": getSerializedEditorValue,
    "setColumnsById": setColumnsById,
    "setEditController": setEditController,
    "finishInitialization": finishInitialization,
    "handleDblClick": handleDblClick,
    "makeActiveCellNormal": makeActiveCellNormal,
    "trigger": trigger
  });

  ...
}
```

### Customization of `init()`

`jquery_plugins/SlickGrid/slick.grid.js`
``` js
function SlickGrid(container, data, columns, options) {
  ...
  function init() {
    ...

    // Ekohe Delete: Customized finishInitialization() will be called in WulinMasterGrid()
    // if (!options.explicitInitialization) {
    //   finishInitialization();
    // }
  }

  $.extend(this, {
    ...
    // Ekohe Modify: Expose init() to WulinMasterGrid
    // "init": finishInitialization,
    "init": init,
    ...
  }

  // Ekohe Delete: Will be called in WulinMasterGrid()
  // init();
  }
}
```

`master/grid.js`
``` js
function WulinMasterGrid(container, data, columns, options) {
  ...

  // Ekohe Add: Customization of init()
  function wulinInit() {
    // Call SlickGrid's init()
    _self.init();

    // Use customized commitCurrentEdit() for editController
    _self.setEditController({
      "commitCurrentEdit": wulinCommitCurrentEdit,
      "cancelCurrentEdit": _self.getEditController().cancelCurrentEdit
    });

    // Call customized finishInitialization()
    if (!_self.getOptions().explicitInitialization) {
      wulinFinishInitialization();
    }
  };

  ...
  // Ekohe Add: Call customized initialization
  wulinInit();
}
```

### Customization of `finishInitialization()`

`jquery_plugins/SlickGrid/slick.grid.js`
``` js
// No change
// Will be called in WulinMasterGrid()
```

`master/grid.js`
``` js
function WulinMasterGrid(container, data, columns, options) {
  ...

  // Ekohe Add: Customization of finishInitialization()
  function wulinFinishInitialization() {
    // set columnsById to {} for visibility setting feature
    _self.setColumnsById({});
    // Remove invisible columns
    removeInvisibleColumns();
    // Call SlickGrid's finishInitialization()
    _self.finishInitialization()
    // Use customized handler for `dblclick` event
    _self.getCanvas().on("dblclick", wulinHandleDblClick)
  }

  ...
}
```

### Customization of `handleDblClick()`

`jquery_plugins/SlickGrid/slick.grid.js`
``` js
function SlickGrid(container, data, columns, options) {
  ...

  //////////////////////////////////////////////////////////////////////////////////////////////
  // Ekohe Modify
  //   1. Move the call of gotoCell() to WulinMasterGrid() for changing of entry condition

  function handleDblClick(e) {
    ...

    // Ekohe Delete: Move to WulinMasterGrid() for changing of entry condition
    // if (options.editable) {
    //   gotoCell(cell.row, cell.cell, true);
    // }
  }

  ...
}
```

`master/grid.js`
``` js
function WulinMasterGrid(container, data, columns, options) {
  ...

  // Ekohe Add: Customization of handleDblClick()
  //   1. Only work for editable column
  function wulinHandleDblClick(e) {
    var columns = _self.getColumns();
    var cell = _self.getActiveCell();

    // Call SlickGrids handleDblClick()
    _self.handleDblClick(e);

    // Ekohe Modify: Only work for editable column
    if(isColumnEditable(columns[cell.cell])) {
      _self.gotoCell(cell.row, cell.cell, true);
    }
  }

  ...
}
```

### Customization of `commitCurrentEdit()`

`jquery_plugins/SlickGrid/slick.grid.js`
``` js
function SlickGrid(container, data, columns, options) {
  ...

  function commitCurrentEdit() {
    // No change.
    // Not be used in wulin_master
  }

  ...
}
```

`master/grid.js`
``` js
function WulinMasterGrid(container, data, columns, options) {
  ...

  // Ekohe Add: Customization of commitCurrentEdit()
  //   1. Use current cell instead of the whole row for submit in onCellChange trigger
  function wulinCommitCurrentEdit() {

    // Ekohe Add: Get properties from SlickGrid
    var activeCell = _self.getActiveCell().cell;
    var activeRow = _self.getActiveCell().row;
    var currentEditor = _self.getCellEditor();
    var serializedEditorValue = _self.getSerializedEditorValue()
    var options = _self.getOptions();
    var activeCellNode = _self.getActiveCellNode();
    var submitItem = {};

    var item = _self.getDataItem(activeRow);
    var column = _self.getColumns()[activeCell];

    if (currentEditor) {
      if (currentEditor.isValueChanged()) {
        var validationResults = currentEditor.validate();

        if (validationResults.valid) {
          if (activeRow < _self.getDataLength()) {
            var editCommand = {
              row: activeRow,
              cell: activeCell,
              editor: currentEditor,
              serializedValue: currentEditor.serializeValue(),
              prevSerializedValue: serializedEditorValue,
              execute: function () {
                currentEditor.applyValue(item, currentEditor.serializeValue());
                _self.updateRow(activeRow);
                // Ekohe Delete: Original SlickGrid Logic: Submit item for the whole row
                // trigger(self.onCellChange, {
                //   row: activeRow,
                //   cell: activeCell,
                //   item: item,
                //   grid: self
                // });
              },
              undo: function () {
                currentEditor.applyValue(item, serializedEditorValue);
                _self.updateRow(activeRow);
                // Ekohe Delete: Original SlickGrid Logic: Submit item for the whole row
                // trigger(self.onCellChange, {
                //   row: activeRow,
                //   cell: activeCell,
                //   item: item,
                //   grid: self
                // });
              }
            };

            ...

            // Ekohe Add: Use item info of current cell for submit in onCellChange trigger
            submitItem['id'] = item.id;
            submitItem[column.field] = item[column.field];
            _self.trigger(_self.onCellChange, {
              row: activeRow,
              cell: activeCell,
              item: submitItem,
              editCommand: editCommand
            });

            ...
          }
          ...
        }
      }
      ...
    }
    ...
  }

  ...
}
```

## Customization of `slick.columnpicker.js`

### Design Pattern & Preparation in `SlickColumnPicker()`

##### Create `WulinMasterColumnPicker()` to inherit `SlickColumnPicker()`

`master/columnpicker.js`
``` js
(function($) {
  $.extend(true, window, {
    WulinMaster: {
      ColumnPicker: WulinMasterColumnPicker
    }
  });

  function WulinMasterColumnPicker(columns, grid, options) {
    Slick.Controls.ColumnPicker.call(this, columns, grid, options);

    var _self = this;

    // Customization ...
  }

  WulinMasterColumnPicker.prototype = Object.create(Slick.Controls.ColumnPicker.prototype);
})(jQuery);
```

##### Add new `getter`/`setter`s to `SlickColumnPicker()`

`jquery_plugins/SlickGrid/controls/slick.columnpicker.js`
``` js
function SlickColumnPicker(columns, grid, options) {
  ...

  ///////////////////////////////////////////////////////////
  // Ekohe Add: New getter/setters

  function getMenu() {
    return $menu;
  }

  function getColumnCheckboxes() {
    return columnCheckboxes;
  }
  ...
}
```

##### Expose new APIs in `SlickColumnPicker()`

`jquery_plugins/SlickGrid/controls/slick.columnpicker.js`
``` js
function SlickColumnPicker(columns, grid, options) {
  ...

  // Ekohe Modify: Use extend instead of return to set APIs to this
  $.extend(this, {
  // return {
    "getMenu": getMenu,                                 // Ekohe Add
    "getColumnCheckboxes": getColumnCheckboxes,         // Ekohe Add
    "init": init,                                       // Ekohe Add
    "updateColumn": updateColumn,                       // Ekohe Add
    "handleHeaderContextMenu": handleHeaderContextMenu, // Ekohe Add
    // "destroy": destroy // Ekohe Delete (should use WulinMasterColumnPicker's API)
    "getAllColumns": getAllColumns
  });

  ...
}
```

### Customization of `init()`

`jquery_plugins/SlickGrid/controls/slick.columnpicker.js`
``` js
function SlickColumnPicker(columns, grid, options) {
  ...
  function init() {
    // No change.
    // Will be called in WulinMasterColumnPicker().
  }

  // Ekohe Delete: Change to call init() in WulinMasterColumnPicker()
  // init();

  ...
  }
}
```

`master/columnpicker.js`
``` js
function WulinMasterColumnPicker(columns, grid, options) {
  ...

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

  ...
  // Ekohe Add: Call customized initialization
  wulinInit();
}
```

### Customization of `handleHeaderContextMenu()`

`jquery_plugins/SlickGrid/controls/slick.columnpicker.js`
``` js
function SlickColumnPicker(columns, grid, options) {
  ...
  function handleHeaderContextMenu() {
    // No change.
    // Will be called in WulinMasterColumnPicker().
  }

  ...
  }
}
```

`master/columnpicker.js`
``` js
function WulinMasterColumnPicker(columns, grid, options) {
  ...

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

  ...
}
```

### Customization of `updateColumn()`

`jquery_plugins/SlickGrid/controls/slick.columnpicker.js`
``` js
function SlickColumnPicker(columns, grid, options) {
  ...
  function updateColumn() {
    // No change.
    // Will be called in WulinMasterColumnPicker().
  }

  ...
  }
}
```

`master/columnpicker.js`
``` js
function WulinMasterColumnPicker(columns, grid, options) {
  ...

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

  ...
}
```

### Customization of `destroy()`

`jquery_plugins/SlickGrid/controls/slick.columnpicker.js`
``` js
function SlickColumnPicker(columns, grid, options) {
  ...
  function destroy() {
    // No change.
    // Not be uses in wulin_master.
  }

  ...
  }
}
```

`master/columnpicker.js`
``` js
function WulinMasterColumnPicker(columns, grid, options) {
  ...

  // Ekohe Modify: Customization of destroy()
  function destroy() {
    // Ekohe Modify: Use customized wulinHandleHeaderContextMenu()
    grid.onHeaderContextMenu.unsubscribe(wulinHandleHeaderContextMenu);

    grid.onColumnsReordered.unsubscribe(_self.updateColumnOrder());
    _self.getMenu().remove();
  }

  ...
}
```

### Add `onColumnsPick` event and related processing

`master/columnpicker.js`
``` js
function WulinMasterColumnPicker(columns, grid, options) {
  ...

  function wulinInit() {
    ...

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

  // Ekohe Add
  $.extend(this, {
    // Events
    "onColumnsPick": new Slick.Event(),

    // Methods
    "destroy": destroy
  });

  ...
}
```
