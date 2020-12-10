var dialogIndex = 1;

function displayErrorMessage(message, title, width) {
  if (message === undefined) {
    message = "An unexpected error occured.";
  }
  var message = $('#error-content').text(message);
  message.html(message.html().replace(/\n/g,'<br/>'));
  $('.modal-title').text(title);
  $('#error-modal').modal('open');
}
