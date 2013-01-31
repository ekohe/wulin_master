class <%= class_name %> < ActiveRecord::Base
  <%- if attributes.present? %>
  attr_accessible <%= attributes.map{|attr| ":#{attr.name}"}.join(", ") -%>
  <%- end %>
end