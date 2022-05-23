// Catch the ajax error
$(document).off('ajaxError').on('ajaxError', function myErrorHandler(_, xhr) {
  var msg = xhr.responseText;
  let wulin_oauth;

  var isJsonResponsee = /application\/json/i.test(
    xhr.getResponseHeader("content-type")
  );
  if (isJsonResponsee) {
    msg = xhr.responseJSON["msg"];
    wulin_oauth = xhr.responseJSON["wulin_oauth"]
  }

  switch (xhr.status) {
    case 401:
      let error_message = wulin_oauth ? msg : `You are not authorized to do this operation, please contact admin to update your permission.
      ${msg}`
      displayErrorMessage(
        error_message,
        "Permission denied",
        400
      );
      return false;
    case 500:
      displayErrorMessage("An unexpected error occurred");
      return false;
    default:
      break;
  }
});
