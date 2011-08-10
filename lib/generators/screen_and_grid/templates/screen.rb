class <%= class_name %>Screen < Screen
  title "<%= human_name %>"

  path '/<%= table_name %>'

  grid <%= class_name %>Grid
end