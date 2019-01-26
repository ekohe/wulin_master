# frozen_string_literal: true

class PersonGrid < WulinMaster::Grid
  title 'People'

  model Person

  # path '/people' # Define a different route for the grid

  row_detail useRowClick: true, showTriggerColumn: false, cssClass: 'company_row_detail', panelRows: 4,
             loadingTemplate: '<div class="red-text" style="background: grey; height: 500px;">Loading...</span>', postTemplate: :person,
             hideRow: true

  behavior :change_row_detail_height

  column :first_name
  column :last_name
  column :birthdate

  load_default_actions # Add default toolbar items for this grid
end
