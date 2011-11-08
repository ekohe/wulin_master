var dialogIndex = 1;

function displayErrorMessage(message, title, width) {
  if (title === undefined)
    title = "Error";
  if (message === undefined)
    message = "An unexpected error occured.";
  if (width === undefined)
    width = 300;
    
  dialogId = "dialog_"+dialogIndex;
  
  dialogHtml = $("<div/>").
                  attr('id', dialogId).
                  attr('title', title).
                  append("<h4>").
                  append('<span class="ui-icon ui-icon-alert" style="float: left; margin-right: .2em;"></span>').
                  append(message).
                  append("</h4>").
                  addClass('ui-state-highlight').
                  css('display', 'none');
  
  $('body').append(dialogHtml);

  $('#'+dialogId).dialog({
		autoOpen: true,
		width: width,
		buttons: {
			"Ok": function() { 
				$(this).dialog("close"); 
			} 
		},
    modal: true
	});
	
  dialogIndex++;
}

function displayConfirmationDialog(message, title, confirmCallback, cancelCallback) {
  if (title === undefined)
    title = "Confirmation";
  if (message === undefined)
    message = "Are you sure?";
  if (confirmCallback === undefined)
    confirmCallback = function() {};
  if (cancelCallback === undefined)
    cancelCallback = function() {};
    
  dialogId = "dialog_"+dialogIndex;
  
  dialogHtml = $("<div/>").
                  attr('id', dialogId).
                  attr('title', title).
                  append("<h4>").
                  append(message).
                  append("</h4>").
                  addClass('ui-state-highlight').
                  css('display', 'none');
  
  $('body').append(dialogHtml);

  $('#'+dialogId).dialog({
		autoOpen: true,
		buttons: {
			Yes: function() {
			  confirmCallback();
        $(this).dialog( "close" );
      },
      Cancel: function() {
			  cancelCallback();
        $(this).dialog( "close" );
      }
		},
    modal: true
	});
	
  dialogIndex++;
}