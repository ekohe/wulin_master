// ------------------------------------ UI tools -----------------------------------------
var Ui = {	
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
  
  // Resize grid
  resizeGrid: function(grid) {
    grid.resizeCanvas();
    grid.autosizeColumns();
    grid.filterPanel.generateFilters();
    $(window).resize(function() { 
      grid.resizeCanvas(); 
      grid.autosizeColumns(); 
      grid.filterPanel.generateFilters();
    });
  },
    
  // Check if filter panel is open
  filterPanelOpen: function() {
    return ($('.slick-headerrow-columns:visible').size() > 0 && $( document.activeElement ).parent().attr('class') === 'slick-headerrow-columns');
  },

  // Check if can add or delete records
  addOrDeleteLocked: function() {
    return this.isEditing() || this.isOpen() || this.filterPanelOpen();
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
    $(':input','#new_' + name).not(':button, :submit, :reset, :hidden').not('[readonly]').val('').removeAttr('checked').removeAttr('selected');
    // For chosen
    $('ul.chzn-choices li.search-choice').remove();
  },

  // Create and open dialog
  openDialog: function(name,options) {
    var scope, width, height;
    scope = $( '#' + name + '-form:first' );
    if (options) {
      width = options.form_dialog_width || 600;
      height = options.form_dialog_height || (scope.outerHeight() + 40);
    } else {
      width = 600;
      height = (scope.outerHeight() + 40);
    }
    
    scope.dialog({
      height: height,
      width: width,
      show: "blind",
      modal: true,
      create: function(event, ui) {
        Ui.setupForm(name, false);
			},
			open: function(event, ui) {
			  $('.btn', $(this)).show();
        $('.update_btn', $(this)).hide();
        $('.target_flag', $(this)).hide();
			},
      close: function(event, ui) {
        Ui.closeDialog(name);
      }
    });
  },

  setupForm: function(name, monitor) {
    // Fetch options of select box by ajax 
    var  remotePath = $('#' + name + '-form #remote_paths').val().split(',');
    window._jsonData = window._jsonData || {};
    $.each(remotePath, function(i,path){
      if ($.isEmptyObject(path)) return
      
      var first_input, target = $("select[data-remote-path='" + path + "']"),
      textAttr = target.attr('data-text-attr');
      target.empty();
      if ($.isEmptyObject(window._jsonData[path])) {
        $.getJSON(path, function(itemdata){
          window._jsonData[path] = itemdata;
          $.each(itemdata, function(index, value) {
            target.append("<option value='" + value.id + "'>" + value[textAttr] + "</option>");
          });
          Ui.setupChosen(path, monitor);
        });
      } else {
        $.each(window._jsonData[path], function(index, value) {
          target.append("<option value='" + value.id + "'>" + value[textAttr] + "</option>");
        });
        Ui.setupChosen(path, monitor);
      }
    });
    
    first_input = $( '#' + name + '-form input:text' ).first();
    if ($.isEmptyObject(first_input.attr('data-date'))) {
      first_input.focus();
    }
  },
  
  setupChosen: function(path, monitor) {
    setTimeout(function(){
      var afterSetupChosen = $("select[data-remote-path='" + path + "']").data('afterSetupChosen');
      if (monitor) {
        $("select[data-remote-path='" + path + "']").chosen().change(function(){
          $('input.target_flag:checkbox[data-target="' + $(this).attr('data-target') + '"]').attr('checked', 'checked');
        });
      } else {
        $("select[data-remote-path='" + path + "']").chosen();
      }
      
      if( afterSetupChosen ) {
        afterSetupChosen();
      }
    }, 100);
  },

  // Close dialog
  closeDialog: function(name) {
    var $form = $( '#' + name + '-form' );
    
    $form.find("input:text").val("");
    $form.find(".field_error").text("");
    setTimeout(function(){
      Ui.highlightCreatedRows(name);
      // gridManager.operatedIds = [];
    }, 300);
    window._focused = {};
    $form.dialog("destroy");
    if ($('#screen_content #' + name + '-form').size() == 0) {
      $('body > #' + name + '-form:first').prependTo($('#screen_content'));
      $('body > #' + name + '-form').remove();
    }
  },


  // Highlight the created rows after close the dialog
  highlightCreatedRows: function(name) {
    var grid = gridManager.getGrid(name),
    createdRows = [];
    $.each(grid.operatedIds, function(){
      if (grid.getRowByRecordId(this) && grid.getRowByRecordId(this).row) {
        createdRows.push(grid.getRowByRecordId(this).row);
      }
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
    var currentGrid = null;
    currentGridContainer = $('.grid_container:visible');
    if (currentGridContainer.size() == 0) {
      return null;
    }
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
  },
	
	formatData: function(grid, arrayData) {
	  var data = {}, columns;
    columns = grid.loader.getColumns();
	  $.each(columns, function(index, column){
	    data[column['id']] = arrayData[index];
	  })
	  return data;
	}

};