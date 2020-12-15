var dialogIndex = 1;

function displayErrorMessage(message, title, width) {
  if (message === undefined) {
    message = "An unexpected error occured.";
  }
  $escapeHtml = escapeHtml(message)
  $final_message = simpleFormat($escapeHtml)

  $('#error-content').html($final_message);
  $('.modal-title').text(title);
  $('#error-modal').modal('open');
}
