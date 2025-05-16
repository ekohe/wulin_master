var dialogIndex = 1;

function displayErrorMessage(message, title, width) {
  if (message === undefined) {
    message = '予期しないエラーが発生しました。';
  }
  escapedHtml = escapeHtml(message);
  finalMessage = simpleFormat(escapedHtml);

  $('#error-content').html(finalMessage);
  $('#error-modal .modal-title').text(title || 'エラー');
  $('#error-modal').modal('open');
}

const displayCustomizedConfirmModal = (params) => {
  const {
    message = '本当によろしいですか？',
    title = '確認',
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
