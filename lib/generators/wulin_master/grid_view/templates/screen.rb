class <%= class_name %>Screen < WulinMaster::Screen
  title '<%= human_name %>'

  path '/<%= table_name %>'

  grid <%= class_name %>Grid
end