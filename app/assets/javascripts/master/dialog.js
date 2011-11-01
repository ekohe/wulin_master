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