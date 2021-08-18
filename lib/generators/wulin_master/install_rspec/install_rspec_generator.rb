# frozen_string_literal: true

module WulinMaster
  class InstallRspecGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    def create_rspec__directory
      empty_directory "spec/requests"
    end

    def copy_filterable_test_file
      copy_file "screen_controllers_filterable_spec.rb", "spec/requests/screen_controllers_filterable_spec.rb"
    end

    def copy_sortable_test_file
      copy_file "screen_controllers_sortable_spec.rb", "spec/requests/screen_controllers_sortable_spec.rb"
    end
  end
end
