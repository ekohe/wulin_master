var dialogIndex = 1;

function displayErrorMessage(message, title, width) {
  if (message === undefined) {
    message = "An unexpected error occured.";
  }
  $('#error-content').text(message);
  $('#error-modal').modal('open');
}
