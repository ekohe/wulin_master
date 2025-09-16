let form = $('form');
let successCallback = (data) => true;
let failureCallback = (data) => true;

const objectName = () => {
  const formId = form.attr('id');
  const newRegExp = /^new_(.*)$/;
  const editRegExp = /^edit_(.*)$/;
  if (newRegExp.test(formId)) {
    return newRegExp.exec(formId)[1];
  } else {
    return editRegExp.exec(formId)[1];
  }
};

const submitButton = () => $('#submit input:submit', form);

const disableForm = () => {
  $('input', form).attr('disabled', 'disabled').css('opacity', 0.5);
  // Save the submit button text to the original value
  submitButton().data('originalValue', submitButton().val()).val('Please wait...');
};

const enableForm = () => {
  $("input", form).removeAttr('disabled').css('opacity', 1.0);
  // Restore saved submit button text value
  $('#submit input:submit', form).val(submitButton().data('originalValue'));
  $("input:first", form).focus();
};

const formSubmitted = () => {
  clearErrors();
  const ajaxOptions = {
    type: 'POST',
    url: form.attr('action') + ".json",
    data: form.serializeArray(),
    dataType: 'json',
    success: (data) => handleInviteResponse(data),
    failure: (data) => {
      displayErrorMessage('An unexpected occured, please try again.');
      enableForm();
      failureCallback(data);
    }
  };

  $.ajax(ajaxOptions);
  disableForm();
  return false;
};

const handleInviteResponse = (data) => {
  if (data.success) {
    if (data.count) {
      if (data.count == 1) {
        displayNewNotification('One record successfully created!');
      } else {
        displayNewNotification(data.count + ' records created!');
      }
    } else {
      displayNewNotification('Successfully created!');
    }
    enableForm();
    successCallback(data);
  } else {
    if (data.error_message) {
      displayValidationErrors(data.error_message);
    }
    displayNewNotification('Your form contains some errors, please try again.');
    enableForm();
  }
};

const displayValidationErrors = (errors) => {
  for (const error in errors) {
    displayValidationError(error, errors[error]);
  }
};

const displayValidationError = (field, errors) => {
  const fieldSelector = "#" + objectName() + "_" + field;
  const errorContainerForField = errorContainer($(fieldSelector));
  errorContainerForField.html(errors.join(', '));
};

const errorContainer = (field) => {
  if (field.siblings('div.field_error').length > 0) {
    return field.siblings('div.field_error');
  } else {
    const errorField = $('<div/>');
    errorField.addClass('field_error');
    field.parent().append(errorField);
    return errorField;
  }
};

const clearErrorField = (field) => {
  $(field).html('');
};

const clearErrors = () => {
  $('.field_error', form).each((index, errorField) => {
    clearErrorField(errorField);
  });
};

window.initializeWulinForm = (wulinForm, aSuccessCallback, aFailureCallback) => {
  form = $(wulinForm);
  if (aSuccessCallback) {
    successCallback = aSuccessCallback;
  }
  if (aFailureCallback) {
    failureCallback = aFailureCallback;
  }
  form.bind('submit', () => formSubmitted());
};
