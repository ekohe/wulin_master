
$.fn.append_loader = function() {
  $(this).parent().append('<div class="ajax-loading"></div>')
}

$.fn.remove_loader = function() {
  $(this).parent().find(".ajax-loading").remove();
}