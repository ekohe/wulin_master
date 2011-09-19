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
        css_class = self.options[:class] || ''
        css_class += " toolbar_icon_#{self.icon}" unless css_class.include?("toolbar_icon_#{self.icon}")
        self.options.merge!(:class => css_class)
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

    # Rendering
    # ---------
    def view_path
      File.join(File.dirname(__FILE__), '..', '..', '..', 'app', 'views')
    end

    # Satisfy render_to_string
    def action_name
      ""
    end

    # Render the grid
    def render
      ActionView::Base.new(view_path).render(:partial => "toolbar_item", :locals => {:toolbar_item => self})
    end
  end
end