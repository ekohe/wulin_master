form = $('form')
successCallback = (data) ->
  true
  
failureCallback = (data) ->
  true

objectName = ->
  formId = form.attr('id')
  newRegExp = /^new_(.*)$/
  editRegExp = /^edit_(.*)$/
  if newRegExp.test(formId)
    return newRegExp.exec(formId)[1]
  else
    return editRegExp.exec(formId)[1]

submitButton = ->
  $('#submit input', form)

disableForm = ->
  $('input', form).attr('disabled', 'disabled').css('opacity', 0.5)
  # Save the submit button text to the original value
  submitButton().data('originalValue', submitButton().val()).val('Please wait...')

enableForm = ->
  $("input", form).removeAttr('disabled').css('opacity', 1.0)
  # Restore saved submit button text value
  $('#submit input', form).val(submitButton().data('originalValue'))
  $("input:first", form).focus()

formSubmitted = ->
  clearErrors()
  ajaxOptions =
    type: 'POST'
    url: form.attr('action')
    data: form.serializeArray()
    dataType: 'json'
    success: (data) ->
      handleInviteResponse data
    failure: (data) ->
      displayErrorMessage 'An unexpected occured, please try again.'
      enableForm()
      failureCallback(data)

  $.ajax ajaxOptions  
  disableForm()
  false
  
handleInviteResponse = (data) ->
  if data.success
    displayNewNotification 'Successfully created!'
    enableForm()
    successCallback(data)
  else
    if data.error_message?
      displayValidationErrors data.error_message
    displayNewNotification 'Your form contains some errors, please try again.'
    enableForm()

displayValidationErrors = (errors) ->
  displayValidationError error, errors[error] for error of errors
  
displayValidationError = (field, errors) ->
  fieldSelector = "#"+objectName()+"_"+field
  errorContainerForField = errorContainer($(fieldSelector))
  errorContainerForField.html(errors.join(', '))
  
errorContainer = (field) ->
  if field.siblings('div.field_error').length > 0
    field.siblings('div.field_error')
  else
    errorField = $('<div/>')
    errorField.addClass('field_error')
    field.parent().append(errorField)
    errorField

clearErrorField = (field) ->
  $(field).html('')

clearErrors = ->
  clearErrorField errorField for errorField in $('.field_error', form)

window.initializeWulinForm = (wulinForm, aSuccessCallback, aFailureCallback) ->
  form = $(wulinForm)
  successCallback = aSuccessCallback if aSuccessCallback?
  failureCallback = aFailureCallback if aFailureCallback?
  form.bind('submit', -> formSubmitted())
