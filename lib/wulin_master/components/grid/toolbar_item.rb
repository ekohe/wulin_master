module WulinMaster
  class ToolbarItem

    attr_accessor :title, :javascript, :icon, :options

    def initialize(title, options={})
      @title = title

      @javascript = options.delete(:javascript)
      @icon = options.delete(:icon)

      options[:href] = '#' unless options[:href]
      @options = options
    end

    def javascript?
      !!@javascript
    end
    
    def icon?
      !!@icon
    end

    def anchor_tag_options
      if icon?
        css_classes = []
        css_classes += self.options[:class].split(' ') if self.options[:class].present?
        css_classes << "toolbar_icon_#{self.icon}" unless css_classes.include?("toolbar_icon_#{self.icon}")
        self.options.merge!(:class => css_classes.uniq.join(' '))
      else
        self.options[:class] = self.options[:class].split(" ").delete_if{|e| e.include?('toolbar_icon')}.join(" ")
      end

      if javascript?
        self.options.merge!(:href => '#',
        :onclick => self.javascript + "; return false;")
      else
        self.options.delete(:href)
        self.options.delete(:onclick)
      end
      
      self.options
    end

    # Satisfy render_to_string
    def action_name
      ""
    end

  end
end