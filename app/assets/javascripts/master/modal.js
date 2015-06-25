function displaySimpleMessage(message, openCallback) {
  defaultTitle = ''
  defaultMessage = ''
  $modal = $('#simple_modal');
  openModal($modal, message);
}

function displayNormalMessage(message, title) {
  defaultTitle = 'Notice'
  defaultMessage = ''
  $modal = $('#normal_modal');
  openModal($modal, message, title, defaultMessage, defaultTitle);
}

function displayErrorMessage(message, title) {
  defaultTitle = 'Error'
  defaultMessage = 'An unexpected error occured.'
  $modal = $('#error_modal');
  openModal($modal, message, title, defaultMessage, defaultTitle);
}

function displayConfirmMessage(callback, message, title) {
  defaultTitle = 'Confirmation';
  defaultMessage = 'Are you sure to do this ?';
  $modal = $('#confirm_modal');
  openModal($modal, message, title, defaultMessage, defaultTitle);

  if (callback != undefined) {
    $modal.find('.yes').off('click').on('click', function(){
      $modal.modal('hide');
      callback();
    });
  }
}

function displayGeneralMessage(openCallback, confirmCallback, cancelButton, yesButton, message, title) {
  $modal = $('#general_modal');
  displayCommonMessage($modal, openCallback, confirmCallback, cancelButton, yesButton, message, title);
}

function displayStandardMessage(openCallback, confirmCallback, cancelButton, yesButton, message, title) {
  $('#general_modal').clone().appendTo('body #content').attr('id', 'standard_modal');
  $modal = $('#standard_modal');
  displayCommonMessage($modal, openCallback, confirmCallback, cancelButton, yesButton, message, title);
}

function displayDoubleMessage(openCallback, confirmCallback, cancelButton, yesButton, message, title) {
  $('#general_modal').clone().appendTo('body #content').attr('id', 'double_modal');
  $modal = $('#double_modal');
  displayCommonMessage($modal, openCallback, confirmCallback, cancelButton, yesButton, message, title);
}

function displayCommonMessage(modal, openCallback, confirmCallback, cancelButton, yesButton, message, title) {
  defaultTitle = '';
  defaultMessage = '';

  if(yesButton != undefined){
    modal.find('.modal-footer .yes').val(yesButton);
  } else {
    modal.find('.modal-footer .yes').hide();
  }

  if(cancelButton != undefined){
    modal.find('.modal-footer .cancel').val(cancelButton);
  } else {
    modal.find('.modal-footer .cancel').hide();
  }

  openModal(modal, message, title, defaultMessage, defaultTitle);

  modal.on('hidden.bs.modal', function(){
    modal.find('.modal-footer .cancel').val('Cancel').show();
    modal.find('.modal-footer .yes').val('Yes').show();
  });

  modal.on('shown.bs.modal', function(){
    if (openCallback != undefined) {
      openCallback();
      openCallback = null;
    }
  });

  modal.find('.yes').off('click').on('click', function(){
    if (confirmCallback != undefined) {
      modal.modal('hide');
      confirmCallback();
      confirmCallback = null;
    }
  });
}

function openModal(modal, message, title, defaultMessage, defaultTitle) {
  if (title != undefined)
    modal.find('.modal-title').html(title);

  if (message != undefined)
    modal.find('.modal-body').html(message);

  var $modalBody = modal.find('.modal-body');
  var innerHeight = $modalBody.children().first().height();
  $modalBody.height(innerHeight);

  modal.modal();
  modal.on('hidden.bs.modal', function(){
    modal.find('.modal-title').html(defaultTitle);
    modal.find('.modal-body').html(defaultMessage);
  });
}