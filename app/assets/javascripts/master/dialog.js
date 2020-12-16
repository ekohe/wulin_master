var dialogIndex = 1;

function displayErrorMessage(message, title, width) {
  if (message === undefined) {
    message = "An unexpected error occured.";
  }
  escapedHtml = escapeHtml(message)
  finalMessage = simpleFormat(escapedHtml)

  $('#error-content').html(finalMessage);
  $('.modal-title').text(title);
  $('#error-modal').modal('open');
}
