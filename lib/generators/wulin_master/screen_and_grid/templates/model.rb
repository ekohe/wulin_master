class <%= class_name %> < ActiveRecord::Base
  attr_accessible <% attributes.select {|attr| attr.reference? }.map{|attr| ":#{attr.name}"}.join(", ") -%>
end