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
      if(this.getCellEditor() != null) editing = true;
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

  // Check if filter panel is open (Not in use since Material Design implementation)
  filterPanelOpen: function() {
    return ($('.slick-headerrow-columns:visible').size() > 0 && $( document.activeElement ).parent().attr('class') === 'slick-headerrow-columns');
  },

  // Check if the grid is being filtered
  isFiltering: function() {
    return $(document.activeElement).parent().hasClass('slick-header-column');
  },

  // Check if can add or delete records
  addOrDeleteLocked: function() {
    return this.isEditing() || this.isOpen() || this.isFiltering();
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
    $.get(grid.path + '/' + action + grid.query, function(data){
      Ui.createModelModal(grid, data, {
        ready: function(modal, trigger) {
          Ui.setupForm(grid, false);
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
      timeFormat: 'HH:mm',
      timeOnly: false,
      stepMinute: 1,
      minuteGrid: 0,
      beforeShow: function() { calendarOpen = true; },
      onClose: function() { calendarOpen = false; }
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
          var formable = n.formable === false ? false : true;

          var editorChoices = n.choices;
          // Use editor's source instead of grid's source
          if (n.editor.source) {
            var match = /^.*(source=.*)$/igm.exec(n.choices);
            var grid_source = match[1];
            editorChoices = n.choices.replace(grid_source, 'source=' + n.editor.source);
          }

          remotePath.push([n.field, editorChoices, formable]);
        }
      } else if (currentData && n['choices_column']) {
        choicesColumn.push([n.field, currentData[n['choices_column']]]);
      }
    });

    // Fetch select options from remote
    if (remotePath.length > 0) {
      $.each(remotePath, function(i, n) {
        var field = n[0];
        var path = n[1];
        var formable = n[2];
        if (!path || !formable) return;

        var first_input;
        var target = $("select[data-field='" + field + "']", scope);
        var source = target.attr('data-source');
        if (target.size() == 1) {
          $('option[value!=""]', target).remove();

          $.getJSON(path, function(itemdata){
            $.each(itemdata, function(index, value) {
              if ($.isPlainObject(value)) {
                target.append(
                  "<option value='" + value.id + "'>" +
                  value[source] +
                  "</option>"
                );
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
        var target = $("select[data-field='" + field + "']", scope);
        var source = target.attr('data-source');
        if (target.size() == 1) {
          $('option[value!=""]', target).remove();

          $.getJSON(path, function(itemdata){
            $.each(itemdata, function(index, value) {
              if ($.isPlainObject(value)) {
                target.append("<option value='" + value.id + "'>" + value[source] + "</option>");
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
        var target = $("select[data-field='" + field + "']", scope);
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

    // Layout
    $('.ui-dialog-titlebar').hide();
    $('.ui-resizable-handle').hide();
    // $('.chzn-container').width('100%');
    // $('.chzn-drop').width('100%');
    // $('.chzn-search input').width('96%');
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

  // Close Modal
  closeModal: function(name) {
    var $form = $( '#' + name + '_form' );
    window._focused = {};
    $form.closest('.modal').modal('close');
    $form.closest('.modal').remove();
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
    if (currentGridContainer.size() === 0) {
      return null;
    }
    gridName = currentGridContainer.attr('id').split('grid_')[1];

    if (gridManager.grids.length == 1) {
      currentGrid = gridManager.grids[0];
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

  getModalSize: function(grid, data) {
    var width, height;
    $('body').append(data);
    var modalHeight = $('.create_form .title').outerHeight() +             // Title
                      $('.create_form form').outerHeight() +               // Fields
                      $('.create_form .submit').outerHeight() +            // Button
                      120;                                                 // Padding
    if (grid.options) {
      width = grid.options.form_dialog_width || 600;
      height = grid.options.form_dialog_height || modalHeight;
    } else {
      width = 600;
      height = modalHeight;
    }
    $('.create_form').remove();
    return { width: width, height: height };
  },

  baseModal: function(options = {}) {
    var $modal = $('<div/>')
      .addClass('modal')
      .appendTo($('body'));
    var $modalContent = $('<div/>')
      .addClass('modal-content')
      .appendTo($modal);

    $.extend(options, {
      complete: function() {
        $modal.remove();
      }
    });
    $modal.modal(options);
    $modal.modal('open');

    return $modal;
  },

  headerModal: function(title, options = {}) {
    var $headerModal = this.baseModal(options)
      .addClass('modal-fixed-footer')
      .css({overflow: 'hidden'});
    var $modalHeader = $('<div/>')
      .addClass('modal-header')
      .append($('<span/>').text(title))
      .append($('<i/>').text('close').addClass('modal-close material-icons right'))
      .prependTo($headerModal);
    var $modalFooter = $('<div/>')
      .addClass('modal-footer')
      .append($('<div/>').addClass('confirm-btn btn right disabled').text('Confirm'))
      .append($('<div/>').addClass('btn-flat modal-close').text('Cancel'))
      .appendTo($headerModal);

    return $headerModal;
  },

  createModelModal: function(grid, data, options) {
    $.extend(options, {
      startingTop: '5%',
      endingTop: '5%',
    });

    var modalSize = this.getModalSize(grid, data);
    var $modelModal = this.baseModal(options)
      .width(modalSize.width)
      .height(modalSize.height)
      .css({'max-height': '90%'});

    $modelModal.find('.modal-content').append(data);
  },

  createJsonViewModal: function(jsonData) {
    this.headerModal('JSON View').find('.modal-content')
      .JSONView(jsonData)
      .JSONView('collapse');
  },

  formatData: function(grid, arrayData) {
    var data = {}, columns;
    columns = grid.loader.getColumns();
    $.each(columns, function(index, column){
      data[column['id']] = arrayData[index];
    });
    return data;
  }

};
