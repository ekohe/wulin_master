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

    // Difference to SlickGrid:
    //   1. submit updated cell only instead of the whole row

    this.getEditorLock().commitCurrentEdit = function() {

      // get properties from SlickGrid
      var activeCell = this.getActiveCell().cell;
      var activeRow = this.getActiveCell().row;
      var currentEditor = this.getCellEditor();
      var serializedEditorValue = this.getSerializedEditorValue()
      var options = this.getOptions();
      var activeCellNode = this.getActiveCellNode();

      var item = this.getDataItem(activeRow);
      var column = columns[activeCell];
      var submitItem = {};

      if (currentEditor) {
        if (currentEditor.isValueChanged()) {
          var validationResults = currentEditor.validate();

          if (validationResults.valid) {
            if (activeRow < this.getDataLength()) {
              var editCommand = {
                row: activeRow,
                cell: activeCell,
                editor: currentEditor,
                serializedValue: currentEditor.serializeValue(),
                prevSerializedValue: serializedEditorValue,
                execute: function () {
                  currentEditor.applyValue(item, currentEditor.serializeValue());
                  this.updateRow(activeRow);
                }.bind(this),
                undo: function () {
                  currentEditor.applyValue(item, serializedEditorValue);
                  this.updateRow(activeRow);
                }.bind(this)
              };

              if (options.editCommandHandler) {
                this.makeActiveCellNormal();
                options.editCommandHandler(item, column, editCommand);
              } else {
                editCommand.execute();
                this.makeActiveCellNormal();
              }

              // submit current cell only insteaf of the whole row
              submitItem['id'] = item.id;
              submitItem[column.field] = item[column.field];
              this.trigger(this.onCellChange, {
                row: activeRow,
                cell: activeCell,
                item: submitItem,
                editCommand: editCommand
              });

            } else {
              var newItem = {};
              currentEditor.applyValue(newItem, currentEditor.serializeValue());
              this.makeActiveCellNormal();
              this.trigger(this.onAddNewRow, {item: newItem, column: column, grid: this});
            }

            // check whether the lock has been re-acquired by event handlers
            return !this.getEditorLock().isActive();
          } else {
            // Re-add the CSS class to trigger transitions, if any.
            $(activeCellNode).removeClass("invalid");
            $(activeCellNode).width();  // force layout
            $(activeCellNode).addClass("invalid");

            this.trigger(this.onValidationError, {
              editor: currentEditor,
              cellNode: activeCellNode,
              validationResults: validationResults,
              row: activeRow,
              cell: activeCell,
              column: column,
              grid: this
            });

            currentEditor.focus();
            return false;
          }
        }

        this.makeActiveCellNormal();
      }
      return true;
    }.bind(this)

    //////////////////////////////////////////////////////////////////////////////////////////////
    // New API for WulinMaster

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
  }

  WulinMasterGrid.prototype = Object.create(Slick.Grid.prototype);
})(jQuery);
