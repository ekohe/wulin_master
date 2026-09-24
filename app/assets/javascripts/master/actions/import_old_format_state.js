WulinMaster.actions.ImportOldFormatState = $.extend(
  {},
  WulinMaster.actions.BaseAction,
  {
    name: "import_old_format_state",

    handler: function () {
      var grid = this.getGrid();
      var ids = grid.getSelectedIds();

      if (ids.length != 1) {
        displayErrorMessage("Please select a grid state.");
        return;
      }

      var gridStateId = ids[0];
      var modal = Ui.headerModal("Import Old Format", {
        openNow: false,
        onOpenStart: function (modal) {
          $(modal).css({width: "640px", height: "520px", maxHeight: "90%"});
          $(modal).find(".modal-content").html(
            "<p>Paste a state value from a previous event. It will be converted to the current format and saved on the selected grid state.</p>" +
            "<textarea class='old-format-state-value' style='height:280px;font-family:monospace;'></textarea>"
          );
        }
      });

      var footer = Ui.appendModalFooter("Save", modal);
      footer.find(".confirm-btn").on("click", function () {
        var raw = $.trim(modal.find(".old-format-state-value").val());
        if (!raw) {
          displayErrorMessage("Paste a state value.");
          return;
        }

        $.post("/wulin_master/grid_states/import_old_format", {id: gridStateId, state_value: raw}, function (response) {
          if (response.success) {
            modal.modal("close");
            displayNewNotification("State value imported.");
            grid.loader.reloadData();
          } else {
            displayErrorMessage(response.message || "We're sorry, but something went wrong");
          }
        });
      });

      modal.modal("open");
    }
  }
);

WulinMaster.ActionManager.register(WulinMaster.actions.ImportOldFormatState);
