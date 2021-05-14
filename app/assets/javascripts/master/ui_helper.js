// ------------------------------------ UI tools -----------------------------------------
var Ui = {
  // return true if the dialog of grid with "name" is open, unless return false
  isOpen: function () {
    return $('.ui-dialog:visible').size() > 0;
  },

  // check if the grid is being edited
  isEditing: function () {
    var editing = false;
    $.each(gridManager.grids, function () {
      if (this.getCellEditor() != null) editing = true;
    });
    return editing;
  },

  // Resize grid
  resizeGrid: function (grid) {
    grid.resizeCanvas();
    grid.autosizeColumns();
    grid.filterPanel.generateFilters();
    $(window).resize(function () {
      grid.resizeCanvas();
      grid.autosizeColumns();
      grid.filterPanel.generateFilters();
    });
  },

  // Check if filter panel is open (Not in use since Material Design implementation)
  filterPanelOpen: function () {
    return (
      $('.slick-headerrow-columns:visible').size() > 0 &&
      $(document.activeElement).parent().attr('class') ===
        'slick-headerrow-columns'
    );
  },

  // Check if the grid is being filtered
  isFiltering: function () {
    return $(document.activeElement).parent().hasClass('slick-header-column');
  },

  // Check if can add or delete records
  addOrDeleteLocked: function () {
    return this.isEditing() || this.isOpen() || this.isFiltering();
  },

  // Select grid names
  selectGridNames: function () {
    var gridContainers = $('.grid_container'),
      gridName;
    return $.map(gridContainers, function (container) {
      gridName = $.trim($(container).attr('id').split('grid_')[1]);
      if (gridName) {
        return gridName;
      }
    });
  },

  // Refresh create form when continue create new record
  refreshCreateForm: function (grid) {
    var name = grid.name;
    $.get(grid.path + '/wulin_master_new_form' + grid.query, function (data) {
      newFormDom = $(data);
      $('#' + name + '_form:visible').closest('.modal-content').html(newFormDom);
      setTimeout(function () {
        Ui.setupForm(grid, false);
      }, 350);
      Ui.setupComponents(grid);
    });
  },

  // Reset form
  resetForm: function (name) {
    $(':input', '#new_' + name)
      .not(':button, :submit, :reset, :hidden')
      .not('[readonly]')
      .val('')
      .removeAttr('checked')
      .removeAttr('selected');
    // For chosen
    $('ul.chzn-choices li.search-choice').remove();
  },

  // Create and open dialog
  openDialog: function (grid, action) {
    $.get(grid.path + "/" + action + grid.query, function (data) {
      Ui.createModelModal(grid, data, {
        dismissible: false,
        onOpenEnd: function () {
          /*
           * needDuplicateSelectedRows will duplicate selected rows.
           * For examle in the comment https://gitlab.ekohe.com/ekohe/hbs/bss_core/-/issues/37
           * You need set needDuplicateSelectedRows to be true before call openDialog to make it happen.
           */
          if(grid.options['needDuplicateSelectedRows']) {
            var selectedIndexes = grid.getSelectedRows();
            Ui.setupForm(grid, false, selectedIndexes);
          } else {
            Ui.setupForm(grid, false);
          }
          Ui.setupComponents(grid);
        },
        onCloseStart: function (modal) {
          $(".materialnote", modal).materialnote("destroy");
          $(".note-popover").remove();
          // Need reset to false at the end to avoid side effect.
          grid.options['needDuplicateSelectedRows'] = false;
        },
      });
    });
  },

  setupComponents: function (grid, scope) {
    var name = grid.name;
    scope = scope || `#${name}_form`;

    $(`${scope} select.select2[data-required=false][multiple]`).each((_, e) => {
      $(e).find("option[value='']").remove()
    })

    // init select2
    $(`${scope} select.select2`).each((_, e) => {
      $(e).select2({
        placeholder: "",
        allowClear: true,
        width: "100%"
      }).on("select2:unselecting", function() {
        $(this).data("unselecting", true);
      }).on("select2:opening", function(e) {
        if ($(this).data("unselecting")) {
          $(this).parents(".field").find("label").removeClass("active")
          $(this).removeData("unselecting")
          e.preventDefault()
        }
      })

      $(e).on("select2:open", (evt) => {
        $(evt.target).parents(".field").find("label").addClass("active")
      })

      $(e).on("select2:close", (evt) => {
        let val = $(evt.target).val()
        if (val) {
          // do nothing
        } else {
          $(evt.target).parents(".field").find("label").addClass("active")
        }

        var flag = $(
          `${scope} input.target_flag:checkbox[data-target="${$(e).attr(
            'data-target'
          )}"]`
        );
        if (flag.size() > 0) flag.prop('checked', true);
      })
    })

    // materialize input[type=text]
    // since we have already imp lemented the input-outlined feature in the _form.html.haml
    // I think we can comment the follow line code.
    // $(`${scope} input[type=text]`).parent().addClass('input-field');

    // make label active for input with value
    $(`${scope} .field`)
      .filter(function () {
        return !!$(this).find('input').val();
      })
      .find('label')
      .addClass('active');
    $(`${scope} input[data-time]`).siblings('label').addClass('active');

    // setup datepicker
    $(`${scope} input[data-datetime]`).each(function() {
      let that = this
      $(that)
      .inputmask('wulinDateTime')
      .flatpickr($.extend({}, fpConfigFormDateTime, onCalendarOpenClose));
    });
    $(`${scope} input[data-date]`).each(function() {
      let that = this
      $(that)
      .inputmask('wulinDate')
      .flatpickr($.extend({}, fpConfigFormDate, onCalendarOpenClose));
    });
    $(`${scope} input[data-time]`).each(function() {
      let that = this
      $(that)
      .inputmask('wulinTime')
      .flatpickr($.extend({}, fpConfigTime, { appendTo: $(that).parent()[0] }));
    });
  },

  setupForm: function (grid, monitor, selectedIndexes, scope) {
    var name = grid.name;
    var scope = scope || `#${name}_form`;
    var $scope = $(scope);
    var remotePath = [];
    var choicesColumn = [];
    var distinctColumn = [];
    var path;
    var formType = $scope.data('action');
    var columns = window[name + '_columns'] || grid.getColumns();
    var currentData = {};

    if (grid.loader) currentData = grid.loader.data[grid.getSelectedRows()[0]];

    // special handling for 'choices' and 'choices_column' options
    $.each(columns, function (i, n) {
      if (n['choices'] && typeof n['choices'] == 'string') {
        if (n['distinct'] && formType != 'create') {
          distinctColumn.push([n.field, n['choices']]);
        } else {
          var formable = n.formable === false ? false : true;

          var editorChoices = n.choices;
          // Use editor's source instead of grid's source
          if (n.editor.source) {
            var match = /^.*(source=.*)$/gim.exec(n.choices);
            var grid_source = match[1];
            editorChoices = n.choices.replace(
              grid_source,
              'source=' + n.editor.source
            );
          }

          remotePath.push([n.field, editorChoices, formable]);
        }
      } else if (currentData && n['choices_column']) {
        choicesColumn.push([n.field, currentData[n['choices_column']]]);
      }
    });

    var fillValuesWillRun = false;

    // Fetch select options from remote
    if (remotePath.length > 0) {
      $.each(remotePath, function (i, n) {
        var field = n[0];
        var path = n[1];
        var formable = n[2];
        if (!path || !formable) return;

        var first_input;
        var target = $("select[data-field='" + field + "']", $scope);
        var source = target.attr('data-source');
        if (target.size() == 1) {
          $('option[value!=""]', target).remove();

          $.getJSON(path, function (itemdata) {
            $.each(itemdata, function (index, value) {
              if ($.isPlainObject(value)) {
                target.append(
                  "<option value='" +
                    value.id +
                    "'>" +
                    value[source] +
                    '</option>'
                );
              } else {
                target.append(
                  "<option value='" + value + "'>" + value + '</option>'
                );
              }
            });
            Ui.setupChosen(grid, target, $scope, selectedIndexes);
          });
          fillValuesWillRun = true;
        }
      });
    }

    // Fetch distinct select options from remote
    if (distinctColumn.length > 0) {
      $.each(distinctColumn, function (i, n) {
        var field = n[0];
        var path = n[1];
        if (!path) return;

        var first_input;
        var target = $("select[data-field='" + field + "']", $scope);
        var source = target.attr('data-source');
        if (target.size() == 1) {
          $('option[value!=""]', target).remove();

          $.getJSON(path, function (itemdata) {
            $.each(itemdata, function (index, value) {
              if ($.isPlainObject(value)) {
                target.append(
                  "<option value='" +
                    value.id +
                    "'>" +
                    value[source] +
                    '</option>'
                );
              } else {
                target.append(
                  "<option value='" + value + "'>" + value + '</option>'
                );
              }
            });
            target.append('<option>Add new Option</option>');
            Ui.setupChosen(grid, target, $scope, selectedIndexes);
          });
          fillValuesWillRun = true;
        }
      });
    }

    // Fetch select options from current data
    if (choicesColumn.length > 0) {
      $.each(choicesColumn, function (i, n) {
        var field = n[0];
        var first_input;
        var target = $("select[data-field='" + field + "']", $scope);
        if (target.size() == 1) {
          $('option[value!=""]', target).remove();
          $.each(n[1], function (index, value) {
            target.append(
              "<option value='" + value + "'>" + value + '</option>'
            );
          });
          Ui.setupChosen(grid, target, $scope, selectedIndexes);
          fillValuesWillRun = true;
        }
      });
    }

    if (fillValuesWillRun == false && typeof selectedIndexes != 'undefined') {
      fillValues($scope, grid, selectedIndexes);
    }

    first_input = $(`${scope}`, $scope).first();
    if (first_input.attr('data-date')) {
      first_input.focus();
    }

    // Layout
    $('.ui-dialog-titlebar').hide();
    $('.ui-resizable-handle').hide();

    // For detail add, pass the filter value / column in the parameters
    if (grid.master && grid.master.filter_column && grid.master.filter_value) {
      hidden_master_id = $("<input type='hidden'/>")
        .attr('name', grid.master.filter_column)
        .val(grid.master.filter_value);
      $('form', $scope).append(hidden_master_id);
    }
    Ui.preventPressEnterKeySubmitForm(`${scope} form`);
  },

  preventPressEnterKeySubmitForm: function (formSelector) {
    $("body")
      .off("keypress", formSelector)
      .on("keypress", formSelector, function (event) {
        let isTextarea = /textarea/i.test(event.target.nodeName) || event.target.className.includes("note-editable");
        if (!isTextarea && event.keyCode === 13) {
          return false;
        }
      });
  },

  setupChosen: function (grid, target, scope, selectedIndexes) {
    if (typeof selectedIndexes != 'undefined') {
      fillValues(scope, grid, selectedIndexes);
    }
    target.trigger('change');
    target.trigger('chosen:updated');
    Ui.unCheckEmpty(target);
    Ui.addNewOption(target);
  },

  // Add new option for distinct column
  addNewOption: function (target) {
    $('#' + target.attr('id') + '_chosen')
      .off('click')
      .on('click', 'li:contains("Add new Option")', function () {
        $(
          '#' +
            target.attr('id') +
            '_chosen .chosen-single .search-choice-close'
        ).trigger('mouseup');
        Ui.createAddOptionModal(target);
      });
  },

  // Uncheck select column when value is empty
  unCheckEmpty: function (target) {
    if (!target.val()) {
      $(
        'input.target_flag:checkbox[data-target="' +
          target.attr('data-target') +
          '"]'
      ).prop('checked', false);
    }
  },

  // Close Modal
  closeModal: function (name) {
    var $form = $('#' + name + '_form');
    window._focused = {};
    $form.closest('.modal').modal('close');
    $form.closest('.modal').remove();
  },

  // Flash the notification
  flashNotice: function (ids, action) {
    var recordSize = $.isArray(ids) ? ids.length : ids.split(',').length,
      recordUnit = recordSize > 1 ? 'records' : 'record',
      actionDesc =
        action === 'delete' ? 'has been deleted!' : 'has been created!';

    if (recordSize > 0) {
      $('.notice_flash').remove();
      $('#indicators').before(
        '<div class="notice_flash">' +
          recordSize +
          ' ' +
          recordUnit +
          ' ' +
          actionDesc +
          '</div>'
      );
      $('.notice_flash').fadeOut(7000);
    }
  },

  // Find the selected grid
  findCurrentGrid: function () {
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
        $.each(gridManager.grids, function () {
          if (this.getSelectedRows().length > 0) currentGrid = this;
        });
      }
    }
    return currentGrid;
  },

  getModalSize: function (grid, data, willBeRemovedContainerClassName = 'create_form') {
    var width, height;
    $('body').append(data);
    var modalHeight =
      $(`.${willBeRemovedContainerClassName} .title`).outerHeight() + // Title
      $(`.${willBeRemovedContainerClassName} form`).outerHeight() + // Fields
      $(`.${willBeRemovedContainerClassName} .submit`).outerHeight() +  // Submit
      $(`.${willBeRemovedContainerClassName} .modal-footer`).outerHeight()  // Footer
      + 60; // Padding
    if (grid.options) {
      width = grid.options.form_dialog_width || 900;
      height = grid.options.form_dialog_height || modalHeight;
    } else {
      width = 900;
      height = modalHeight;
    }
    $(`.${willBeRemovedContainerClassName}`).remove();
    return { width: width, height: height };
  },

  baseModal: function (options) {
    options = options || {};

    var $modal = $('<div/>').addClass('modal').appendTo($('body'));
    var $modalContent = $('<div/>').addClass('modal-content').appendTo($modal);


    $.extend(options, {
      onCloseEnd: function () {
        $modal.remove();
      },
    });
    $modal.modal(options);

    const { openNow = true } = options

    if (openNow) {
      $modal.modal('open');
    }

    return $modal;
  },

  headerModal: function (title, options) {
    options = options || {};
    var $headerModal = this.baseModal(options)
      .addClass('modal-fixed-footer')
      .css({ overflow: 'hidden' });
    var $modalHeader = $('<div/>')
      .addClass('modal-header')
      .append($('<span/>').text(title))
      .append(
        $('<i/>').text('close').addClass('modal-close material-icons right')
      )
      .prependTo($headerModal);

    return $headerModal;
  },

  modalFooter: function (btnName) {
    var $modalFooter = $('<div/>')
      .addClass('modal-footer')
      .append($('<div/>').addClass('confirm-btn btn right').text(btnName))
      .append($('<div/>').addClass('btn-flat modal-close').text('Cancel'));

    return $modalFooter;
  },

  pdfDownloadFooter: function (pdfUrl) {
    var $pdfDownloadFooter = Ui.modalFooter('Download PDF');
    $pdfDownloadFooter.find('.confirm-btn').on('click', function () {
      window.open(pdfUrl);
      $pdfDownloadFooter.parent().modal('close');
    });

    return $pdfDownloadFooter;
  },

  createModelModal: function (grid, data, options, willBeRemovedContainerClassName) {
    $.extend(options, {
      startingTop: '5%',
      endingTop: '5%',
    });

    var modalSize = this.getModalSize(grid, data, willBeRemovedContainerClassName);
    var $modelModal = this.baseModal(options)
      .width(modalSize.width)
      .height(modalSize.height)
      .css({ 'max-height': '90%' });

    __globalWillAppend = true;
    $modelModal.addClass('modal-fixed-footer');
    $modelModal.find('.modal-content').append(data);

    var $modelFooter = $('<div/>').addClass('modal-footer').attr('id','modal-footer').appendTo($modelModal);

    __globalWillAppend = false;
    return $modelModal;
  },

  createJsonViewModal: function (jsonData) {
    var $jsonViewModal = this.headerModal('JSON View');
    $jsonViewModal.find('.modal-content').jsonViewer(jsonData);
  },

  createAddOptionModal: function (inputBox) {
    var $addOptionModal = Ui.baseModal({
      onOpenEnd: function (modal, trigger) {
        var $fieldDiv = $('<div />').addClass('input-field');
        $fieldDiv.append('<label for="distinct_field"">New Option</label>');
        $fieldDiv.append(
          '<input id="distinct_field" type="text" name="distinct_field">'
        );
        $(modal)
          .find('.modal-content')
          .append($('<h5/>').text('Add new option'))
          .append($fieldDiv);
      },
    }).width(400);

    var $modalFooter = Ui.modalFooter('Add Option').appendTo($addOptionModal);
    $modalFooter.find('.confirm-btn').on('click', function () {
      var optionText = $addOptionModal.find('#distinct_field').val();
      if (optionText) {
        $('option:contains("Add new Option")', inputBox).before(
          '<option value="' + optionText + '">' + optionText + '</option>'
        );
        inputBox.val(optionText);
        $(
          'input.target_flag:checkbox[data-target="' +
            inputBox.attr('data-target') +
            '"]'
        ).attr('checked', 'checked');
        inputBox.trigger('chosen:updated');
        $addOptionModal.modal('close');
      } else {
        alert('New option can not be blank!');
      }
    });
  },

  formatData: function (grid, arrayData) {
    var data = {},
      columns;
    columns = grid.loader.getColumns();
    $.each(columns, function (index, column) {
      data[column['id']] = arrayData[index];
    });
    return data;
  },
};
