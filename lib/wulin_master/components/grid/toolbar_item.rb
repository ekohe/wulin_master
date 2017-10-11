# frozen_string_literal: true

module WulinMaster
  class ToolbarItem
    attr_accessor :title, :javascript, :icon, :options

    def initialize(title, options = {})
      @title = title

      @javascript = options.delete(:javascript)
      @icon = options.delete(:icon)

      options[:href] = 'javascript:void(0);' unless options[:href]
      @options = options
    end

    def javascript?
      !@javascript.nil?
    end

    def icon?
      !@icon.nil?
    end

    def anchor_tag_options
      if icon?
        css_classes = []
        css_classes += options[:class].split(' ') if options[:class].present?
        # css_classes << "toolbar_icon_#{icon}" unless css_classes.include?("toolbar_icon_#{icon}")
        css_classes << "toolbar_manually_enable" if options[:manually_enable]
        options[:class] = css_classes.uniq.join(' ')
      else
        options[:class] = options[:class].split(" ").delete_if { |e| e.include?('toolbar_icon') }.join(" ")
      end

      if javascript?
        options.merge!(href: '#',
                       onclick: javascript + "; return false;")
      else
        options.delete(:href)
        options.delete(:onclick)
      end

      options
    end

    # Satisfy render_to_string
    def action_name
      ""
    end
  end
end
