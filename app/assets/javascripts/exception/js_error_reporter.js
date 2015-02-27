window.onerror = function(msg, file, line){
  var message = "Error: " + msg + "\nurl: " + window.location + "\nfile: " + file + "\nline #: " + line;
  alert(message);
  // $.ajax({
  //   type: 'POST',
  //   url:  'wulin_master/js_error_report',
  //   data: {message: message}
  // });
};