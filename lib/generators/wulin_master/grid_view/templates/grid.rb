class <%= class_name %>Grid < WulinMaster::Grid
  title '<%= human_name %>'

  model <%= class_name %>

  # path '/<%= table_name %>' # Define a different route for the grid
<% r =  class_name.classify.constantize.columns.map { |c| c.name } %>
<% r.each do |column| -%>
  column :<%= column.include?(" ") ? "\"#{column}\"" : column %>
<% end -%>

  load_default_actions # Add default toolbar items for this grid
end