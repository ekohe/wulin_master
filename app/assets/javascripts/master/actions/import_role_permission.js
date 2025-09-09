// Toolbar Item 'Import Role Permission'

WulinMaster.actions.ImportRolePermission = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'import_role_permission',

  loadDropzone: function(callback) {
    // Check if Dropzone is already loaded
    if (window.Dropzone) {
      callback();
      return;
    }

    // Load CSS
    if (!$('link[href*="dropzone"]').length) {
      $('<link>')
        .attr('rel', 'stylesheet')
        .attr('href', '/assets/dropzone.min.css')
        .attr('data-dropzone-css', 'true') // Add identifier for cleanup
        .appendTo('head');
    }

    // Load JS
    $.getScript('/assets/dropzone.min.js')
      .done(function() {
        // Disable Dropzone auto-discovery
        window.Dropzone.autoDiscover = false;
        callback();
      })
      .fail(function() {
        displayErrorMessage("Failed to load file upload component.");
      });
  },

  cleanupDropzone: function() {
    // Remove CSS
    $('link[data-dropzone-css="true"]').remove();

    // Remove JS (set to undefined, can't truly delete from window)
    if (window.Dropzone) {
      window.Dropzone = undefined;
      delete window.Dropzone;
    }
  },

  handler: function() {
    const grid = this.getGrid();
    const self = this;

        // Load Dropzone first, then create modal
    this.loadDropzone(function() {
      let modal = Ui.baseModal({
        onOpenStart: function (modal, trigger) {
          var content = `
          <h5>Import Role Permission</h5>
          <div id="import-role-permission-dropzone" class="dropzone" style="border-radius: 10px; border: 2px dashed rgba(42, 177, 201, 0.8);">
            <div class="dz-message" style="color: rgba(42, 177, 201, 0.8);">
              Drop JSON file to import or click to browse
            </div>
          </div>
          `
          $(modal).find(".modal-content").html(content)

          // Store modal reference for Dropzone callbacks
          const $modal = $(modal);

          // Initialize Dropzone after modal content is added
          setTimeout(function() {
            new Dropzone("#import-role-permission-dropzone", {
              url: "/roles/import_role_permission",
              acceptedFiles: ".json,application/json",
              maxFiles: 1,
              addRemoveLinks: true,
              paramName: "import_role_permission_file",
              headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
              },
              success: function(file, response) {
                displayNewNotification(response.message || "Import successful!");
                self.cleanupDropzone(); // Clean up Dropzone resources
                grid.loader.reloadData();
                this.removeFile(file);
                $modal.modal("close");
              },
              error: function(file, response) {
                let errorMsg = "An error occurred while importing the file.";
                if (typeof response === 'string') {
                  try {
                    response = JSON.parse(response);
                  } catch(e) {}
                }
                if (response && response.error) {
                  errorMsg = response.error;
                }
                displayErrorMessage(errorMsg);
                self.cleanupDropzone(); // Clean up Dropzone resources
                $modal.modal("close");
              }
            });
          }, 100);
        },
        onCloseEnd: function () {
          self.cleanupDropzone(); // Clean up Dropzone resources
          this.remove();
        }
      }).width("600px").height("auto");
    });
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.ImportRolePermission);
