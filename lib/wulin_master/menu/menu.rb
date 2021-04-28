# frozen_string_literal: true

module WulinMaster
  class Menu < Array
    # Rendering
    # ----------
    def view_path
      [File.expand_path('../../../app/views', __dir__)]
    end

    # Satisfy render_to_string
    def action_name
      ""
    end

    # Render the menu
    def render
      ActionView::Base.with_empty_template_cache.new(
        ActionView::LookupContext.new(view_path),
        {},
        nil
      ).render(partial: "/menu", locals: {menu: self})
    end
  end

  class MenuEntry
    attr_reader :title, :path, :options

    def initialize(title, path, options)
      @title = title
      @path = path
      @options = options
    end

    def submenu?
      false
    end

    def hidden?
      @options[:hidden]
    end

    def active_paths
      return nil if options[:active_paths].blank? && @options[:reverse].blank?
      paths = options.delete(:active_paths) || []
      paths_list = paths.is_a?(Array) ? paths.join(',') : paths
      paths_list += "," + @options[:reverse] if reverse_present?
      paths_list
    end

    def reverse_present?
      @options[:reverse].present?
    end

    def reverse_path
      @options[:reverse]
    end
  end

  class SubMenu < Menu
    attr_reader :title

    def initialize(title)
      @title = title
    end

    def submenu?
      true
    end
  end
end
