function displaySimpleMessage(message, openCallback) {
  defaultTitle = ''
  defaultMessage = ''
  $modal = $('#simple_modal');
  openModal($modal, message);

  $modal.on('shown.bs.modal', function(){
    if (openCallback != undefined) {
      openCallback();
      openCallback = null;
    }
  });
}

function displayNormalMessage(message, title) {
  defaultTitle = 'Notice'
  defaultMessage = ''
  $modal = $('#normal_modal');
  openModal($modal, message, title, defaultMessage, defaultTitle);
}

function displayNormalMessageWithoutButton(message, title) {
  defaultTitle = 'Notice'
  defaultMessage = ''
  $modal = $('#normal_modal').clone().prependTo('body #content').attr('id', 'normal_modal_without_button');;
  $modal.find('.modal-footer').hide();
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
  displayMessage($modal, openCallback, confirmCallback, cancelButton, yesButton, message, title);
}

function displayGridMessage(openCallback, confirmCallback, cancelButton, yesButton, message, title) {
  $('#general_modal').clone().prependTo('body #content').attr('id', 'grid_modal');
  $modal = $('#grid_modal');
  displayMessage($modal, openCallback, confirmCallback, cancelButton, yesButton, message, title);
}

function displayContinuousMessage(openCallback, confirmCallback, cancelButton, yesButton, message, title) {
  $('#general_modal').clone().prependTo('body #content').attr('id', 'continuous_modal');
  $modal = $('#continuous_modal');
  displayMessage($modal, openCallback, confirmCallback, cancelButton, yesButton, message, title);
}

function displayMessage(modal, openCallback, confirmCallback, cancelButton, yesButton, message, title) {
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
  if (title != undefined){
    modal.find('.modal-title').html(title);
  }

  if (message != undefined)
    modal.find('.modal-body').html(message);

  var $modalBody = modal.find('.modal-body');
  var innerHeight = $modalBody.children().first().height();
  $modalBody.height(innerHeight);

  modal.modal();
  modal.on('hidden.bs.modal', function(){
    modal.find('.modal-title').html(defaultTitle);
    // modal.find('.modal-body').html(defaultMessage);
  });
}

function displayCustomMessage(openCallback, confirmCallback1, confirmCallback2, cancelCallback, button1, button2, cancelButton, message, title) {
  defaultTitle = 'Title';
  defaultMessage = '';
  $modal = $('#custom_modal');

  if(button1 != undefined){
    $modal.find('.modal-footer .btn1').val(button1);
  } else {
    $modal.find('.modal-footer .btn1').hide();
  }

  if(button2 != undefined){
    $modal.find('.modal-footer .btn2').val(button2);
  } else {
    $modal.find('.modal-footer .btn2').hide();
  }

  openModal($modal, message, title, defaultMessage, defaultTitle);

  $modal.on('hidden.bs.modal', function(){
    $modal.find('.modal-footer .btn1').val('Button1').show();
    $modal.find('.modal-footer .btn2').val('Button2').show();
  });

  $modal.on('shown.bs.modal', function(){
    if (openCallback != undefined) {
      openCallback();
      openCallback = null;
    }
  });

  $modal.find('.btn1').off('click').on('click', function(){
    if (confirmCallback1 != undefined) {
      $modal.modal('hide');
      confirmCallback1();
      confirmCallback1 = null;
    }
  });

  $modal.find('.btn2').off('click').on('click', function(){
    if (confirmCallback2 != undefined) {
      $modal.modal('hide');
      confirmCallback2();
      confirmCallback2 = null;
    }
  });

  if(cancelButton != undefined){
    $modal.find('.cancel').off('click').on('click', function(){
    if (cancelCallback != undefined) {
      $modal.modal('hide');
      cancelCallback();
      cancelCallback = null;
    }
  });
  } else {
    $modal.find('.cancel').hide();
  }
}

function displayTargetMessage(openCallback, confirmCallback1, confirmCallback2, cancelCallback, button1, button2, cancelButton, message, title) {
  defaultTitle = 'Select Targets';
  defaultMessage = '';
  $modal = $('#target_modal');

  if(button1 != undefined){
    $modal.find('.modal-footer .btn1').val(button1);
  } else {
    $modal.find('.modal-footer .btn1').hide();
  }

  if(button2 != undefined){
    $modal.find('.modal-footer .btn2').val(button2);
  } else {
    $modal.find('.modal-footer .btn2').hide();
  }

  openModal($modal, message, title, defaultMessage, defaultTitle);

  $modal.on('shown.bs.modal', function(){
    if (openCallback != undefined) {
      openCallback();
    }
  });

  $modal.find('.btn1').off('click').on('click', function(){
    if (confirmCallback1 != undefined) {
      confirmCallback1();
    }
  });

  $modal.find('.btn2').off('click').on('click', function(){
    if (confirmCallback2 != undefined) {
      confirmCallback2();
    }
  });

  if(cancelButton != undefined){
    $modal.find('.cancel').off('click').on('click', function(){
    if (cancelCallback != undefined) {
      $modal.modal('hide');
      cancelCallback();
    }
  });
  } else {
    $modal.find('.cancel').hide();
  }

  $modal.on('hidden.bs.modal', function(){
    $modal.find('.modal-footer .btn1').val('Button1').show();
    $modal.find('.modal-footer .btn2').val('Button2').show();
    openCallback = null;
    confirmCallback1 = null;
    confirmCallback2 = null;
    cancelCallback = null;
  });
}

function displayServiceMessage(openCallback, confirmCallback1, confirmCallback2, cancelCallback, button1, button2, cancelButton, message, title) {
  defaultTitle = 'Select Services';
  defaultMessage = '';
  $modal = $('#service_modal');

  if(button1 != undefined){
    $modal.find('.modal-footer .btn1').val(button1);
  } else {
    $modal.find('.modal-footer .btn1').hide();
  }

  if(button2 != undefined){
    $modal.find('.modal-footer .btn2').val(button2);
  } else {
    $modal.find('.modal-footer .btn2').hide();
  }

  openModal($modal, message, title, defaultMessage, defaultTitle);

  $modal.on('shown.bs.modal', function(){
    if (openCallback != undefined) {
      openCallback();
    }
  });

  $modal.find('.btn1').off('click').on('click', function(){
    if (confirmCallback1 != undefined) {
      confirmCallback1();
    }
  });

  $modal.find('.btn2').off('click').on('click', function(){
    if (confirmCallback2 != undefined) {
      confirmCallback2();
    }
  });

  if(cancelButton != undefined){
    $modal.find('.cancel').off('click').on('click', function(){
    if (cancelCallback != undefined) {
      $modal.modal('hide');
      cancelCallback();
    }
  });
  } else {
    $modal.find('.cancel').hide();
  }

  $modal.on('hidden.bs.modal', function(){
    openCallback = null;
    confirmCallback1 = null;
    confirmCallback2 = null;
    cancelCallback = null;
  });
}