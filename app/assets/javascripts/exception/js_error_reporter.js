window.onerror = function(msg, file, line, col, error){
  var message = "Error: " + msg + "\nurl: " + window.location + "\nfile: " + file + "\nline #: " + line;
  $.ajax({
    type: 'POST',
    url:  '/wulin_master/js_error_report',
    data: { message: message, stack: error.stack }
  });
};
