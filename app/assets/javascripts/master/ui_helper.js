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
    $.get(grid.path + '/wulin_master_new_form' + grid.query, function(data){
      newFormDom = $(data);
      $('#' + name + '_form:visible form').replaceWith(newFormDom.find('form'));
      setTimeout(function(){ Ui.setupForm(grid, false); }, 350);
      Ui.setupComponents(grid);
    });
  },

  // Reset form
  resetForm: function(name) {
    $(':input','#new_' + name).not(':button, :submit, :reset, :hidden').not('[readonly]').val('').removeAttr('checked').removeAttr('selected');
    // For chosen
    $('ul.chzn-choices li.search-choice').remove();
  },

  // Create and open dialog
  openDialog: function(grid, action, options, callback) {
    var scope, width, height, name;
    name = grid.name;

    $.get(grid.path + '/' + action + grid.query, function(data){
      $( '#' + name + '_form').remove();
      
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
          Ui.setupForm(grid, false);
          if ($.isFunction(callback))
            callback();
        },
        close: function(event, ui) {
          scope.dialog('destroy');
          scope.remove();
        }
      });
    });
  },

  setupComponents: function(grid) {
    var name = grid.name;
    // setup select as chosen
    $('#' + name + '_form select[data-required="true"]').chosen();
    $('#' + name + '_form select[data-required="false"]').chosen({allow_single_deselect: true});

    $('#' + name + '_form select').off('change').on('change', function(){
      var flag = $('#' + name + '_form input.target_flag:checkbox[data-target="' + $(this).attr('data-target') + '"]');
      if (flag.size() > 0) flag.attr('checked', 'checked');
    });

    // setup datepicker
    $('#' + name + '_form input[data-date]').datepicker({ dateFormat: 'yy-mm-dd' });
    $('#' + name + '_form input[data-datetime]').datetimepicker({
      onlyTime: false,
      dateFormat: "yy-mm-dd",
      timeFormat: 'hh:mm',
      timeOnly: false,
      stepMinute: 1,
      minuteGrid: 0,
      beforeShow: function() { calendarOpen = true },
      onClose: function() { calendarOpen = false }
    });
    $('#' + name + '_form input[data-time]').timepicker({});
  }, 

  setupForm: function(grid, monitor) {
    var remotePath = [];
    var choicesColumn = [];
    var distinctColumn = [];
    var path;
    var name = grid.name;
    var scope = $('#' + name + '_form');
    var formType = scope.data('action');
    var columns = window[name + "_columns"] || grid.getColumns();
    var currentData = {};

    if (grid.loader)
      currentData = grid.loader.data[grid.getSelectedRows()[0]];

    // special handling for 'choices' and 'choices_column' options
    $.each(columns, function(i, n) {
      if (n['choices'] && typeof(n['choices']) == 'string') {
        if (n['distinct'] && formType != 'create') {
          distinctColumn.push([n.field, n['choices']]);
        } else {
          remotePath.push([n.field, n['choices']]);
        }
      } else if (n['choices_column']) {
        choicesColumn.push([n.field, currentData[n['choices_column']]]);
      }
    });

    // Fetch select options from remote
    if (remotePath.length > 0) {
      $.each(remotePath, function(i, n) {
        var field = n[0];
        var path = n[1];
        if (!path) return;
      
        var first_input;
        var target = $("select[data-column='" + field + "']", scope);
        var textAttr = target.attr('data-text-attr');
        if (target.size() == 1) {
          $('option[value!=""]', target).remove();
   
          $.getJSON(path, function(itemdata){
            $.each(itemdata, function(index, value) {
              if ($.isPlainObject(value)) {
                target.append("<option value='" + value.id + "'>" + value[textAttr] + "</option>");
              } else {
                target.append("<option value='" + value + "'>" + value + "</option>");
              }
            });
            Ui.setupChosen(target, monitor);
          });

        }
      });
    }

    // Fetch distinct select options from remote
    if (distinctColumn.length > 0) {
      $.each(distinctColumn, function(i, n) {
        var field = n[0];
        var path = n[1];
        if (!path) return;
      
        var first_input;
        var target = $("select[data-column='" + field + "']", scope);
        var textAttr = target.attr('data-text-attr');
        if (target.size() == 1) {
          $('option[value!=""]', target).remove();
   
          $.getJSON(path, function(itemdata){
            $.each(itemdata, function(index, value) {
              if ($.isPlainObject(value)) {
                target.append("<option value='" + value.id + "'>" + value[textAttr] + "</option>");
              } else {
                target.append("<option value='" + value + "'>" + value + "</option>");
              }
            });
            target.append("<option>Add new Option</option>");
          });

        }
      });
    }

    // Fetch select options from current data
    if (choicesColumn.length > 0) {
        $.each(choicesColumn, function(i, n) {
        var field = n[0];
        var first_input;
        var target = $("select[data-column='" + field + "']", scope);
        if (target.size() == 1) {
          $('option[value!=""]', target).remove();
            $.each(n[1], function(index, value) {
              target.append("<option value='" + value + "'>" + value + "</option>");
            });
            Ui.setupChosen(target, monitor);
        }
      });
    }
    
    first_input = $( '#' + name + '_form input:text', scope).first();
    if (first_input.attr('data-date')) {
      first_input.focus();
    }
  },
  
  setupChosen: function(dom, monitor) {
    setTimeout(function(){
      var afterSetupChosen = dom.data('afterSetupChosen');
      if (dom.hasClass("chzn-done")) {
        dom.trigger("liszt:updated");
      } else {
        dom.chosen();
      }

      if( afterSetupChosen ) {
        afterSetupChosen();
      }
    }, 100);
  },

  // Close dialog
  closeDialog: function(name) {
    var $form = $( '#' + name + '_form' );
    
    window._focused = {};
    
    $form.dialog("destroy");
    $form.remove();
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
