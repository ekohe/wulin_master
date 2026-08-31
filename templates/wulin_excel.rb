# wulin_excel -- adds an Excel export button to grid toolbars.
#
# The lightest of the components: no migrations, no generators, no routes, no
# initializers. It reopens WulinMaster::Actions#index and registers a default
# global grid action at load time.

wulin_vendor "wulin_excel"

# Must be imported after master.js: the file touches WulinMaster.actions at the
# top level. wulin_master is always first in the catalog, so ordering holds.
wulin_js "../../vendor/gems/wulin_excel/vendor/assets/javascripts/excel.js"

# Same image-url() problem as wulin_audit, same one-rule fix.
wulin_sass <<~SASS
  .toolbar_icon_excel
    background: url("excel_icon.png") no-repeat top center
SASS

wulin_note "wulin_excel: only grids that call load_default_actions get the export button -- grids that list their actions explicitly do not"
wulin_note "wulin_excel: exports are capped at WulinExcel.maximum_number_of_rows (65535 by default, a leftover .xls limit)"
