var dialogIndex = 1;

function displayErrorMessage(message, title, width) {
  if (message === undefined) {
    message = "An unexpected error occured.";
  }
  $('#error-content').html(message);
  $('.modal-title').text(title);
  $('#error-modal').modal('open');
}
