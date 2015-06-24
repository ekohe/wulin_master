function displaySimpleMessage(message) {
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
  defaultTitle = '';
  defaultMessage = '';
  $modal = $('#general_modal');

  if(yesButton != undefined){
    $modal.find('.modal-footer .yes').val(yesButton);
  } else {
    $modal.find('.modal-footer .yes').hide();
  }

  if(cancelButton != undefined){
    $modal.find('.modal-footer .cancel').val(cancelButton);
  } else {
    $modal.find('.modal-footer .cancel').hide();
  }

  openModal($modal, message, title, defaultMessage, defaultTitle);

  $modal.on('hidden.bs.modal', function(){
    $modal.find('.modal-footer .cancel').val('Cancel');
    $modal.find('.modal-footer .yes').val('Yes');
  });

  if (openCallback != undefined) {
    $modal.on('shown.bs.modal', function(){
      openCallback();
    });
  }

  if (confirmCallback != undefined) {
    $modal.find('.yes').off('click').on('click', function(){
      $modal.modal('hide');
      confirmCallback();
    });
  }
}

function openModal(modal, message, title, defaultMessage, defaultTitle) {
  if (title != undefined)
    modal.find('.modal-title').html(title);

  if (message != undefined)
    modal.find('.modal-body').html(message);

  modal.modal();
  modal.on('hidden.bs.modal', function(){
    modal.find('.modal-title').html(defaultTitle);
    modal.find('.modal-body').html(defaultMessage);
  });
}