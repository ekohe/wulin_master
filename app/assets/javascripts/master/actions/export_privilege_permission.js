// Toolbar Item 'Export Privilege Permission'

WulinMaster.actions.ExportPrivilegePermission = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'export_privilege_permission',

  handler: function(e) {
    const grid = this.getGrid();
    const ids = grid.getSelectedIds();

    const query = $.param({ ids: ids });
    const url = `/privileges/export_privilege_permission${query ? `?${query}` : ''}`;

    const req = new XMLHttpRequest();
    req.open('GET', url, true);
    req.responseType = 'blob';

    req.onload = function() {
      const blob = req.response;
      let filename = 'privileges_permissions.json';
      const cd = req.getResponseHeader('Content-Disposition');
      if (cd) {
        const match = cd.match(/filename="?([^";]+)"?/);
        if (match && match[1]) filename = match[1];
      }

      const link = document.createElement('a');
      link.href = window.URL.createObjectURL(blob);
      link.download = filename;
      link.click();

      window.URL.revokeObjectURL(link.href);
      link.remove();
    };
    req.send();
  },
});
WulinMaster.ActionManager.register(WulinMaster.actions.ExportPrivilegePermission);
