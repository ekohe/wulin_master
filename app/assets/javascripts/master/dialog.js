var dialogIndex = 1;

function displayErrorMessage(message, title, width) {
  if (title === undefined)
    title = "Error";
  if (message === undefined)
    message = "An unexpected error occured.";
  if (width === undefined)
    width = 300;

  var $content = $('<div/>')
    .addClass('modal-content')
    .append($('<h5/>').text(title).addClass('modal-title'))
    .append($('<div/>').text(message).addClass('modal-message'));
  var $footer = $('<div/>')
    .addClass('modal-footer')
    .append($('<div/>').text('OK').addClass('btn right modal-close'));

  var $errorModal = $("<div/>")
    .attr('title', title)
    .addClass('modal info-modal')
    .append($content)
    .append($footer)
    .appendTo($('body'));

  $('.modal').modal('close');
  $errorModal.modal('open');
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
