// Catch the ajax error
$(document).off('ajaxError').on('ajaxError', function myErrorHandler(_, xhr) {
  var msg = xhr.responseText;

  var isJsonResponsee = /application\/json/i.test(
    xhr.getResponseHeader("content-type")
  );
  if (isJsonResponsee) {
    msg = xhr.responseJSON["msg"];
  }

  switch (xhr.status) {
    case 401:
      displayErrorMessage(
        "You are not authorized to do this operation, please contact admin to update your permission. " +
          msg,
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
