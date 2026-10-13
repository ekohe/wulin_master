# frozen_string_literal: true

class <%= class_name %> < ActiveRecord::Base
<% attributes.select(&:reference?).each do |attribute| -%>
  belongs_to :<%= attribute.name %><%= belongs_to_options(attribute) %>
<% end -%>
end
