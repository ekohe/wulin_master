// ------------------------------------ UI tools -----------------------------------------
var Ui = {	
  // Select record id attribute form grid
  selectIds: function(grid){
    var selectedIndexs = grid.getSelectedRows(),
    ids, item;
    if (grid == null) return false;
    if (selectedIndexs.length > 0) {
      ids = $.map(selectedIndexs,function(n, i) { 
        item = grid.loader.data[n];
        return item['id']; 
        }).join();
        return ids;
      } else {
        return false;
      }
    },

    // return true if the dialog of grid with "name" is open, unless return false 
    isOpen: function() {
      return ($(".ui-dialog:visible").size() > 0);
    },

    // check if the grid is being edited
    isEditing: function() {
      var editing = false;
      $.each(gridManager.grids, function(){
        if(this.isEditing()) editing = true;
      });
      return editing;
    },

    // Select grid names
    selectGridNames: function() {
      var gridContainers = $(".grid_container"), gridName;
      return $.map( gridContainers, function(container){
        gridName = $.trim($(container).attr("id").split("grid_")[1]);
        if (gridName) {
          return gridName;
        }
      });
    },

    // Reset form
    resetForm: function(name) {
      $(':input','#new_' + name).not(':button, :submit, :reset, :hidden').val('').removeAttr('checked').removeAttr('selected');
    },

    // Create and open dialog
    openDialog: function(name) {
      $( '#' + name + '-form' ).dialog({
        height: 300,
        width: 500,
        show: "blind",
        modal: true,
        open: function(event, ui) {
					$( '#' + name + '-form input:text' ).first().focus();
					// the dialog show animation makes the first field lose focus so after 400ms we reapply the focus
					setTimeout(function() {
						$( '#' + name + '-form input:text' ).first().focus();
					}, 400);
				},
        close: function(event, ui) { 
          $(this).find("input:text").val("");
          $(this).find(".field_error").text(""); 
          Ui.flashNotice(gridManager.createdIds, 'create');
          setTimeout(function(){
            Ui.highlightCreatedRows(name);
            gridManager.createdIds = [];
            }, 300);
          }
        });
      },

      // Close dialog
      closeDialog: function(name) {
        $( '#' + name + '-form' ).dialog( "close" );
        Ui.flashNotice(gridManager.createdIds, 'create');
        setTimeout(function(){
          Ui.highlightCreatedRows(name);
          gridManager.createdIds = [];
          }, 300);
        },

        // Handle delete confirm with dialog
        deleteGrids: function(ids) {
          $( "#confirm_dialog" ).dialog({
            modal: true,
            buttons: {
              Yes: function() {
                Requests.deleteByAjax(Ui.findCurrentGrid(), ids);
                $( this ).dialog( "close" );
              },
              Cancle: function() {
                $( this ).dialog( "close" );
              }
            }
          });
        },

        // Highlight the created rows after close the dialog
        highlightCreatedRows: function(name) {
          var grid = gridManager.getGrid(name),
          createdRows = [];

          $.each(gridManager.createdIds, function(){
            createdRows.push(grid.getRowByRecordId(this));
          });
          $.each(createdRows, function(){
            $(this).effect( 'highlight', {}, 5000 );
          });
        },

        // Flash the notification
        flashNotice: function(ids, action) {
          var recordSize = $.isArray(ids) ? ids.length : ids.split(',').length,
          recordUnit = recordSize > 1 ? 'records' : 'record',
          actionDesc = action === 'delete' ? 'has been deleted!' : 'has been created!';

          if (recordSize > 0) {
            $('.notice_flash').remove();
            $('#indicators').before('<div class="notice_flash">' + recordSize + ' ' + recordUnit + ' ' + actionDesc + '</div>');
            $('.notice_flash').fadeOut(7000);
          }
        },

        // Find the selected grid
        findCurrentGrid: function() {
          var currentGrid = null,
          currentGridContainer = $('.grid_container:visible'),
          gridName = currentGridContainer.attr('id').split('grid_')[1];

          if (gridManager.grids.length == 1) {
            currentGrid = gridManager.grids[0]
          } else {
            if (currentGridContainer.size() == 1) {
              currentGrid = gridManager.getGrid(gridName);
            } else {
              $.each(gridManager.grids, function(){
                if(this.getSelectedRows().length > 0) currentGrid = this;
              });
            }
          }
          return currentGrid;
        }

      };



      // ------------------------- keypress action --------------------------------------
      (function($) {
        $(document).keypress(function(e){
          var isEditing = Ui.isEditing(), 
          isOpen = Ui.isOpen(),
          grid = Ui.findCurrentGrid(),
          ids = Ui.selectIds(grid),
          gridSize = gridManager.grids.length;

          if (isOpen || isEditing) {
            return true;
          } else {
            if (e.which == 100 || e.which == 68) {  // keypress 'D' for delete
            if (ids) {
              Ui.deleteGrids(ids);
              return false;
            }
            return false;
            } else if (e.which == 99 || e.which == 67) {  // keypress 'C' for show dialog
            if (gridSize > 0 && grid) {
              Ui.openDialog(grid.name);
              return false;
            }
            return false;
          } else {
            return true;
          }
        }	
      });
      })(jQuery);
