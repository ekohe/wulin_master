// ------------------------------------ UI tools -----------------------------------------
var Ui = {
  // return true if the dialog of grid with "name" is open, unless return false
  isOpen: function() {
    return ($(".ui-dialog:visible").size() > 0);
  },

  // check if the grid is being edited
  isEditing: function() {
    var editing = false;
    $.each(gridManager.grids, function() {
      if (this.isEditing()) editing = true;
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
    return ($('.slick-headerrow-columns:visible').size() > 0 && $(document.activeElement).parent().attr('class') === 'slick-headerrow-columns');
  },

  // Check if can add or delete records
  addOrDeleteLocked: function() {
    return this.isEditing() || this.isOpen() || this.filterPanelOpen();
  },

  // Select grid names
  selectGridNames: function() {
    var gridContainers = $(".grid_container"),
      gridName;
    return $.map(gridContainers, function(container) {
      gridName = $.trim($(container).attr("id").split("grid_")[1]);
      if (gridName) {
        return gridName;
      }
    });
  },

  // Refresh create form when continue create new record
  refreshCreateForm: function(grid) {
    var name = grid.name;
    $.get(grid.path + '/wulin_master_new_form' + grid.query, function(data) {
      newFormDom = $(data);
      $('#' + name + '_form:visible form').replaceWith(newFormDom.find('form'));
      setTimeout(function() {
        Ui.setupForm(grid, false);
      }, 350);
      Ui.setupComponents(grid);
    });
  },

  // Reset form
  resetForm: function(name) {
    $(':input', '#new_' + name).not(':button, :submit, :reset, :hidden').not('[readonly]').val('').removeAttr('checked').removeAttr('selected');
    // For chosen
    $('ul.chzn-choices li.search-choice').remove();
  },

  // Create and open dialog
  openDialog: function(grid, action, options, callback) {
    var scope, width, height, name;
    name = grid.name;

    $.get(grid.path + '/' + action + grid.query, function(data) {
      $('#' + name + '_form').remove();

      $('body').append(data);

      scope = $('#' + name + '_form');

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
    $('#' + name + '_form select[data-required="false"]').chosen({
      allow_single_deselect: true
    });

    $('#' + name + '_form select').off('change').on('change', function() {
      var flag = $('#' + name + '_form input.target_flag:checkbox[data-target="' + $(this).attr('data-target') + '"]');
      if (flag.size() > 0) flag.attr('checked', 'checked');
    });

    // setup datepicker
    $('#' + name + '_form input[data-date]').datepicker({
      dateFormat: 'yy-mm-dd'
    });
    $('#' + name + '_form input[data-datetime]').datetimepicker({
      onlyTime: false,
      dateFormat: "yy-mm-dd",
      timeFormat: 'HH:mm',
      timeOnly: false,
      stepMinute: 1,
      minuteGrid: 0,
      beforeShow: function() {
        calendarOpen = true;
      },
      onClose: function() {
        calendarOpen = false;
      }
    });
    $('#' + name + '_form input[data-time]').timepicker({});
  },

  setupForm: function(grid, monitor, selectedIndexes) {
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
      } else if (currentData && n['choices_column']) {
        choicesColumn.push([n.field, currentData[n['choices_column']]]);
      }
    });

    var fillValuesWillRun = false;

    // Fetch select options from remote
    if (remotePath.length > 0) {
      $.each(remotePath, function(i, n) {
        var field = n[0];
        var path = n[1] + "&rand=" + parseInt(Math.random() * 10000000, 10);
        if (!path) return;

        var first_input;
        var target = $("select[data-column='" + field + "']", scope);
        var textAttr = target.attr('data-text-attr');
        if (target.size() == 1) {
          $('option[value!=""]', target).remove();

          $.getJSON(path, function(itemdata) {
            var optionsArr = [];
            $.each(itemdata, function(index, value) {
              if ($.isPlainObject(value)) {
                optionsArr.push("<option value='" + value.id + "'>" + value[textAttr] + "</option>");
              } else {
                optionsArr.push("<option value='" + value + "'>" + value + "</option>");
              }
            });
            target.append(optionsArr.join(''));
            Ui.setupChosen(grid, target, monitor, selectedIndexes);
          });
          fillValuesWillRun = true;
        }
      });
    }

    // Fetch distinct select options from remote
    if (distinctColumn.length > 0) {
      $.each(distinctColumn, function(i, n) {
        var field = n[0];
        var path = n[1] + "&rand=" + parseInt(Math.random() * 10000000, 10);
        if (!path) return;

        var first_input;
        var target = $("select[data-column='" + field + "']", scope);
        var textAttr = target.attr('data-text-attr');
        if (target.size() == 1) {
          $('option[value!=""]', target).remove();
          $.getJSON(path, function(itemdata) {
            var optionsArr = [];
            $.each(itemdata, function(index, value) {
              if ($.isPlainObject(value)) {
                optionsArr.push("<option value='" + value.id + "'>" + value[textAttr] + "</option>");
              } else {
                optionsArr.push("<option value='" + value + "'>" + value + "</option>");
              }
            });
            optionsArr.push("<option>Add new Option</option>");
            target.append(optionsArr.join(''));
            Ui.setupChosen(grid, target, monitor, selectedIndexes);
          });
          fillValuesWillRun = true;
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
          var optionsArr = [];
          $.each(n[1], function(index, value) {
            optionsArr.push("<option value='" + value + "'>" + value + "</option>");
          });
          target.append(optionsArr.join(''));
          Ui.setupChosen(grid, target, monitor, selectedIndexes);
          fillValuesWillRun = true;
        }
      });
    }

    if ((fillValuesWillRun === false) && (typeof(selectedIndexes) != "undefined")) {
      Ui.fillValues(scope, grid, selectedIndexes);
    }

    first_input = $('#' + name + '_form input:text', scope).first();
    if (first_input.attr('data-date')) {
      first_input.focus();
    }
  },

  setupChosen: function(grid, dom, monitor, selectedIndexes) {
    var scope = $('#' + grid.name + '_form');
    if (typeof(selectedIndexes) != "undefined") {
      Ui.fillValues(scope, grid, selectedIndexes);
    }
    var afterSetupChosen = dom.data('afterSetupChosen');
    if (dom.hasClass("chzn-done")) {
      dom.trigger("liszt:updated");
    } else {
      dom.chosen();
    }

    if (afterSetupChosen) {
      afterSetupChosen();
    }
  },

  // Close dialog
  closeDialog: function(name) {
    var $form = $('#' + name + '_form');

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
    currentGridContainer = $(document.activeElement).parents('.grid_container');
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
        $.each(gridManager.grids, function() {
          if (this.getSelectedRows().length > 0) currentGrid = this;
        });
      }
    }
    return currentGrid;
  },

  formatData: function(grid, arrayData) {
    var data = {}, columns;
    columns = grid.loader.getColumns();
    $.each(columns, function(index, column) {
      data[column['id']] = arrayData[index];
    });
    return data;
  },

  fillValues: function(scope, grid, selectedIndexes) {
    var data, inputBox, dataArr, comm = {};
    if (selectedIndexes.length == 1) {
      data = grid.loader.data[selectedIndexes[0]];
      Ui.loadValue(scope, data);
    } else {
      dataArr = $.map(selectedIndexes, function(n, i) {
        return grid.loader.data[n];
      });
      $.each(dataArr, function(index, n) {
        for (var k in n) {
          if (index === 0) {
            if (k != 'id' && k != 'slick_index') comm[k] = n[k];
          } else {
            if ($.type(n[k]) != 'object' && comm[k] !== n[k]) {
              delete comm[k];
            } else if ($.type(n[k]) === 'object' && $.type(comm[k]) === 'object' && !compareArray(comm[k]['id'], n[k]['id'])) {
              delete comm[k];
            }
          }
        }
      });
      Ui.loadValue(scope, comm);
    }
  },

  loadValue: function(scope, data) {
    for (var i in data) {
      if ($('input:text[data-column="' + i + '"]', scope).size() > 0) {
        $('input[data-column="' + i + '"]', scope).val(data[i]);
      } else if ($('textarea[data-column="' + i + '"]', scope).size() > 0) {
        $('textarea[data-column="' + i + '"]', scope).val(data[i]);
      } else if ($('input:checkbox[data-column="' + i + '"]', scope).size() > 0) {
        if (data[i]) {
          $('input:checkbox[data-column="' + i + '"]', scope).attr('checked', 'checked');
        } else {
          $('input:checkbox[data-column="' + i + '"]', scope).removeAttr('checked');
        }
      } else if ($('select[data-column="' + i + '"]', scope).size() > 0) {
        inputBox = $('select[data-column="' + i + '"]', scope);
        if ($.type(data[i]) === 'string') {
          inputBox.val(data[i]);
        } else if ($.type(data[i]) === 'object') {
          if ($.type(data[i]['id']) === 'array') {
            inputBox.val(data[i]['id']);
          } else {
            inputBox.val(data[i]['id']);
          }
        } else if ($.type(data[i]) === 'array') {
          inputBox.val(data[i]);
        }

        inputBox.trigger("change"); // trigger change so that the depend_column selector can update options
        if (inputBox.hasClass("chzn-done")) {
          inputBox.trigger("liszt:updated");
        } else {
          inputBox.chosen();
        }
        Ui.distinctInput(inputBox);
      }
    }
  },

  distinctInput: function(inputBox) {
    var addNewSelect;
    // This is a crazy feature
    if ($('#' + inputBox.attr('id') + '_chzn li:contains("Add new Option")').size() > 0) {
      addNewSelect = $('#' + inputBox.attr('id'));
      $('#' + addNewSelect.attr('id') + '_chzn li:contains("Add new Option")').off('mouseup').on('mouseup', function(event) {
        var $select = addNewSelect;
        var $dialog = $("<div/>").attr({
          id: 'distinct_dialog',
          title: "Add new option",
          'class': "create_form"
        }).css('display', 'none').appendTo($('body'));
        var $fieldDiv = $("<div />").attr({
          style: 'padding: 20px 30px;'
        });
        var $submitDiv = $("<div />").attr({
          style: 'padding: 0 30px;'
        });
        $fieldDiv.append('<label for="distinct_field" style="display: inline-block; margin-right: 6px;">New Option</label>');
        $fieldDiv.append('<input id="distinct_field" type="text" style="width: 250px" size="30" name="distinct_field">');
        $fieldDiv.appendTo($dialog);
        $submitDiv.append('<input id="distinct_submit" class="btn success" type="submit" value=" Add Option " name="commit">');
        $submitDiv.appendTo($dialog);
        $dialog.dialog({
          autoOpen: true,
          width: 450,
          height: 180,
          modal: true,
          buttons: {
            "Cancel": function() {
              $(this).dialog("destroy");
              $(this).remove();
            }
          },
          open: function(event, ui) {
            $('#distinct_submit', $(this)).on('click', function() {
              var optionText = $('#distinct_dialog #distinct_field').val();
              if (optionText) {
                $('option:contains("Add new Option")', $select).before('<option value="' + optionText + '">' + optionText + '</option>');
                $select.val(optionText);
                $('input.target_flag:checkbox[data-target="' + $select.attr('data-target') + '"]').attr('checked', 'checked');
                $select.trigger('liszt:updated');
                $dialog.dialog("destroy");
                $dialog.remove();
              } else {
                alert('New option can not be blank!');
              }
            });
          },
          close: function(event, ui) {
            $(this).dialog("destroy");
            $(this).remove();
          }
        });

        return false;
      });
    }
  }

};
