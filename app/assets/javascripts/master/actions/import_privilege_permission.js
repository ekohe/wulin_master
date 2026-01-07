// Toolbar Item 'Import Privilege Permission'

WulinMaster.actions.ImportPrivilegePermission = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'import_privilege_permission',

  loadDropzone: function(callback) {
    // Check if Dropzone is already loaded
    if (window.Dropzone) {
      callback();
      return;
    }

    // Use the precomputed asset URLs from the layout
    const dropzoneJsUrl = window.DROPZONE_JS_URL || '/assets/dropzone.min.js';
    const dropzoneCssUrl = window.DROPZONE_CSS_URL || '/assets/dropzone.min.css';

    // Load CSS
    if (!$('link[href*="dropzone"]').length) {
      $('<link>')
        .attr('rel', 'stylesheet')
        .attr('href', dropzoneCssUrl)
        .attr('data-dropzone-css', 'true') // Add identifier for cleanup
        .appendTo('head');
    }

    // Load JS
    $.getScript(dropzoneJsUrl)
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
          <h5>Import Privilege Permission</h5>
          <div id="import-privilege-permission-dropzone" class="dropzone" style="border-radius: 10px; border: 2px dashed rgba(42, 177, 201, 0.8);">
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
            new Dropzone("#import-privilege-permission-dropzone", {
              url: "/privileges/import_privilege_permission",
              acceptedFiles: ".json,application/json",
              maxFiles: 1,
              addRemoveLinks: true,
              paramName: "import_privilege_permission_file",
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

WulinMaster.ActionManager.register(WulinMaster.actions.ImportPrivilegePermission);