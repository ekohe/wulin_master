var dialogIndex = 1;

function displayErrorMessage(message, title, width) {
  if (message === undefined) {
    message = "An unexpected error occured.";
  }
  $('#error-content').text(message);
  $('#error-modal').modal('open');
}

function displayConfirmationDialog(message, title, confirmCallback, cancelCallback) {
  if (title === undefined)
    title = "Confirmation";
  if (message === undefined)
    message = "Are you sure?";
  if (confirmCallback === undefined)
    confirmCallback = function() {};
  if (cancelCallback === undefined)
    cancelCallback = function() {};

  dialogId = "dialog_"+dialogIndex;

  dialogHtml = $("<div/>").
                  attr('id', dialogId).
                  attr('title', title).
                  append("<h4>").
                  append(message).
                  append("</h4>").
                  addClass('ui-state-highlight').
                  css('display', 'none');

  $('body').append(dialogHtml);

  $('#'+dialogId).dialog({
    autoOpen: true,
    buttons: {
      Yes: function() {
        confirmCallback();
        $(this).dialog( "destroy" );
      },
      Cancel: function() {
        cancelCallback();
        $(this).dialog( "destroy" );
      }
    },
    modal: true
  });

  dialogIndex++;
}
