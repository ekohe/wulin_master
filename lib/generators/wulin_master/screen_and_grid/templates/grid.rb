class <%= class_name %>Grid < WulinMaster::Grid
  title '<%= human_name %>'

  model <%= class_name %>

  path '/<%= table_name %>'    

  fill_window

<% attributes.each do |column| -%>
  column :<%= column.name.include?(" ") ? "\"#{column.name}\"" : column.name %>
<% end -%>

  load_default_actions # Add default toolbar items for this grid
end