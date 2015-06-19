function displayGeneralMessage(openCallback, confirmCallback, yesButton, message, title) {
  defaultTitle = ''
  defaultMessage = ''

  $modal = $('#general_modal');
  fillModalContent($modal, yesButton, message, title, defaultMessage, defaultTitle);
  $modal.modal();

  if (openCallback != undefined) {
    $modal.on('bs.show.modal', function(){
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

function displayErrorMessage(message, title) {
  defaultTitle = 'Error'
  defaultMessage = 'An unexpected error occured.'

  $modal = $('#error_modal');
  fillModalContent($modal, '', message, title, defaultMessage, defaultTitle);
  $modal.modal();
}

function displayConfirmMessage(callback, message, title) {
  defaultTitle = 'Confirmation'
  defaultMessage = 'Are you sure to do this ?'

  $modal = $('#confirm_modal');
  fillModalContent($modal, null, message, title, defaultMessage, defaultTitle);
  $modal.modal();

  if (callback != undefined) {
    $modal.find('.yes').off('click').on('click', function(){
      $modal.modal('hide');
      callback();
    });
  }
}

function fillModalContent(modal, yesButton, message, title, defaultMessage, defaultTitle){
  if (title != undefined)
    $modal.find('.modal-title').html(title);

  if (message != undefined)
    $modal.find('.modal-body').html(message);

  if(yesButton != undefined)
    $modal.find('.modal-footer .yes').val(yesButton);

  $modal.on('hidden.bs.modal', function(){
    $modal.find('.modal-title').html(defaultTitle);
    $modal.find('.modal-body').html(defaultMessage);
    $modal.find('.modal-footer .yes').val('Yes');
  });
}