Chosen.prototype.search_results_mouseup = function(evt) {
  var target;
  target = $(evt.target).hasClass("active-result") ? $(evt.target) : $(evt.target).parents(".active-result").first();
  if (target.length) {
    this.result_highlight = target;
    this.result_select(evt);
    // return this.search_field.focus();
  }
};