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
  
  // Refresh create form when continue create new record
  refreshCreateForm: function(grid) {
    var name = grid.name;
    $.get(grid.path + '/wulin_master_new_form', function(data){
      newFormDom = $(data);
      $('#' + name + '_form:visible form').replaceWith(newFormDom.find('form'));
      setTimeout(function(){ Ui.setupForm(name, false); }, 350)
    });
  },

  // Reset form
  resetForm: function(name) {
    $(':input','#new_' + name).not(':button, :submit, :reset, :hidden').not('[readonly]').val('').removeAttr('checked').removeAttr('selected');
    // For chosen
    $('ul.chzn-choices li.search-choice').remove();
  },

  // Create and open dialog
  openDialog: function(grid,options) {
    var scope, width, height, name;
    name = grid.name;
    
    $.get(grid.path + '/wulin_master_new_form', function(data){
      $('body').append(data);
      
      scope = $( '#' + name + '_form');
      
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
        close: function(event, ui) {
          scope.dialog('destroy');
          scope.remove();
        }
      });
    });
  },

  setupForm: function(name, monitor) {
    var  remotePath;
    $('#' + name + '_form .chzn-select:not([data-remote-path])').chosen();
    $('#' + name + '_form input[data-date]').datepicker({ dateFormat: 'yy-mm-dd' });
    $('#' + name + '_form input[data-datetime]').datetimepicker({
      onlyTime: false,
      dateFormat: "yy-mm-dd",
      timeFormat: 'hh:mm'
    });
    $('#' + name + '_form input[data-time]').timepicker({});
    
    if ($('#' + name + '_form #remote_paths').val()) {
      // Fetch options of select box by ajax 
      remotePath = $('#' + name + '_form #remote_paths').val().split(',');
      window._jsonData = window._jsonData || {};
      $.each(remotePath, function(i,path){
        if ($.isEmptyObject(path)) return
      
        var first_input, target = $("select[data-remote-path='" + path + "']"),
        textAttr = target.attr('data-text-attr');
        // target.empty();
        $('option[value!=""]', target).remove();
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
    }
    
    first_input = $( '#' + name + '_form input:text' ).first();
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
    var $form = $( '#' + name + '_form' );
    
    // setTimeout(function(){
    //   Ui.highlightCreatedRows(name);
    // }, 300);
    window._focused = {};
    
    $form.dialog("destroy");
    $form.remove();
  },


  // Highlight the created rows after close the dialog
  // highlightCreatedRows: function(name) {
  //   var grid = gridManager.getGrid(name),
  //   createdRows = [];
  //   console.log(grid.operatedIds);
  //   $.each(grid.operatedIds, function(){
  //     if (grid.getRowByRecordId(this) && grid.getRowByRecordId(this).row) {
  //       createdRows.push(grid.getRowByRecordId(this).row);
  //     }
  //   });
  //   $.each(createdRows, function(){
  //     $(this).effect( 'highlight', {}, 5000 );
  //   });
  // },

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
    currentGridContainer = $( document.activeElement ).parents('.grid_container');
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
