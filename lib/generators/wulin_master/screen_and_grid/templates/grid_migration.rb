# frozen_string_literal: true

class <%= migration_class_name %> < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :<%= table_name %> do |t|
<% attributes.each do |attribute| -%>
      t.<%= attribute.type %> :<%= attribute.name %><%= inject_column_options(attribute) %>
<% end -%>
<% unless options[:no_timestamps] %>
      t.timestamps
<% end -%>
    end
  end
end
