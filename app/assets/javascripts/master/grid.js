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

    // Ekohe Add: Customization of finishInitialization()
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

              if (options.editCommandHandler) {
                _self.makeActiveCellNormal();
                options.editCommandHandler(item, column, editCommand);
              } else {
                editCommand.execute();
                _self.makeActiveCellNormal();
              }

              // Ekohe Add: Use item info of current cell for submit in onCellChange trigger
              submitItem['id'] = item.id;
              submitItem[column.field] = item[column.field];
              _self.trigger(_self.onCellChange, {
                row: activeRow,
                cell: activeCell,
                item: submitItem,
                editCommand: editCommand
              });

            } else {
              var newItem = {};
              currentEditor.applyValue(newItem, currentEditor.serializeValue());
              _self.makeActiveCellNormal();
              _self.trigger(_self.onAddNewRow, {item: newItem, column: column, grid: _self});
            }

            // check whether the lock has been re-acquired by event handlers
            return !_self.getEditorLock().isActive();
          } else {
            // Re-add the CSS class to trigger transitions, if any.
            $(activeCellNode).removeClass("invalid");
            $(activeCellNode).width();  // force layout
            $(activeCellNode).addClass("invalid");

            _self.trigger(_self.onValidationError, {
              editor: currentEditor,
              cellNode: activeCellNode,
              validationResults: validationResults,
              row: activeRow,
              cell: activeCell,
              column: column,
              grid: _self
            });

            currentEditor.focus();
            return false;
          }
        }

        _self.makeActiveCellNormal();
      }
      return true;
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
