window.onerror = function(msg, url, line){
  var message = "Error: " + msg + "\nurl: " + url + "\nline #: " + line;
  $.ajax({
    type: 'POST',
    url:  'wulin_master/js_error_report',
    data: {message: message}
  });
}