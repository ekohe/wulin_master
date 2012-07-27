var adjustPanelButtons = function(){
  var $panel = $(".panel_container");
  var $btns = $panel.find(".panel_btns");
  if($btns.length == 0) return false;

  var panelHeight = $panel.height();
  var btnsHeight = $btns.height();
  var margin = (panelHeight - btnsHeight) / 2 * 0.8;
  $btns.css("margin-top", margin + "px");
}