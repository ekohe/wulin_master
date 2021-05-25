var dialogIndex = 1;

function displayErrorMessage(message, title, width) {
  if (message === undefined) {
    message = 'An unexpected error occured.';
  }
  escapedHtml = escapeHtml(message);
  finalMessage = simpleFormat(escapedHtml);

  $('#error-content').html(finalMessage);
  $('#error-modal .modal-title').text(title);
  $('#error-modal').modal('open');
}

const displayCustomizedConfirmModal = (params) => {
  const {
    message = 'Are you sure to do this ?',
    title = 'Confirmation',
    confirmCallBack,
  } = params;
  $('#confirm-content').html(message);
  $('#confirm-modal .modal-title').text(title);
  $('#confirm-modal').modal('open');
  $('#confirmed-btn').off('click').on('click', () => {
    confirmCallBack && confirmCallBack();
    $('#confirm-modal').modal('close');
  });
};
