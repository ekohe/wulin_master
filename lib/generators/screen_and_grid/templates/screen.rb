class <%= class_name %>Screen < Screen
  title "<%= human_name %>"

  path '/<%= underscored_name %>'

  grid :<%= underscored_name %> do
    title "<%= human_name %>"

    base_model <%= class_name %>

    path '/<%= underscored_name %>'    

<% attributes.each do |column| -%>
    column :<%= column.name.include?(" ") ? "\"#{column.name}\"" : column.name %>
<% end -%>
  end
end