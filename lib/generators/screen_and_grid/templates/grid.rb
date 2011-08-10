class <%= class_name %>Grid < WulinMaster::GridConfig
  config do
    title "<%= human_name %>"

    base_model <%= class_name %>

    path '/<%= table_name %>'    

<% attributes.each do |column| -%>
    column :<%= column.name.include?(" ") ? "\"#{column.name}\"" : column.name %>
<% end -%>
  end
end