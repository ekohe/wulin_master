WulinMaster.actions.MakeDefaultGrid = $.extend(
  {},
  WulinMaster.actions.BaseAction,
  {
    name: "make_default_grid",

    handler: function () {
      let grid = this.getGrid();
      let ids = grid.getSelectedIds();
      let self = this;

      if (ids.length != 1) {
        displayErrorMessage("Please select a grid!");
        return;
      }

      let fileId = ids[0];
      let index = grid.getRowByRecordId(fileId).index;
      let selectGrid = grid.getData()[index];
      let gridId = selectGrid.id;
      let gridName = selectGrid.grid_name;
      let stateVal = selectGrid.state_value ? selectGrid.state_value : "";
      let name = selectGrid.name

      let modal = Ui.baseModal({
        onOpenStart: function (modal, trigger) {
          let title = `
        <p>This action will set the selected state as the initial grid state.</p>
        <p style="text-align: center">
        </p>
        <p style="text-align: left">Are you sure?</p>
        `;
          let content = title;
          $(modal).find(".modal-content").html(content);
        },
        onCloseEnd: function () {
          this.remove();
        },
      })
        .width("400px")
        .height("auto");

      let footer = Ui.modalFooter("Set as Initial").appendTo(modal);
      footer.find(".confirm-btn").on("click", function () {
        modal.modal("close");
        const data = {
          id: gridId,
          grid_name: gridName,
          state_val: stateVal,
          name: name
        }
        let url = `/wulin_master/grid_states/set_as_initial`
        $.post(url, data, function(response) {
          if (response.success === true) {
            displayNewNotification("Initial grid has been successfully set!");
            grid.loader.reloadData();
          } else if(response.success === false ) {
            displayErrorMessage(response.message);
          }else{
            displayErrorMessage("We're sorry, but something went wrong");
          }
        })
      });
    },
  }
);

WulinMaster.ActionManager.register(WulinMaster.actions.MakeDefaultGrid);
