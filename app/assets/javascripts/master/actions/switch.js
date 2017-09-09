// Toolbar Item 'Switch Screen'

WulinMaster.actions.Switch = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'switch',

  handler: function() {
    var url = this.switch_to['path'] + '?screen=' + this.switch_to['screen'];
    History.pushState(null, null, url);
    loadPageForHistoryState(url);
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.Switch);
