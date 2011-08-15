module WulinMaster
  class ToolbarItem

    attr_accessor :title, :javascript, :options

    def initialize(title, options={})
      @title = title

      @javascript =  options.delete(:javascript)
      @icon = options.delete(:icon)

      options[:href] = '#' if options[:href].nil?
      @options = options
    end

    def javascript?
      !@javascript.nil?
    end

    def anchor_tag_options
      if @icon
        css_class = self.options[:class] || ''
        css_class += " toolbar_icon_#{@icon}" unless css_class.include?("toolbar_icon_#{@icon}")
        @options.merge!(:class => css_class)
      end

      if javascript?
        return self.options.merge(:href => '#',
        :onclick => self.javascript + "; return false;")
      else
        return self.options
      end
    end

    # Rendering
    # ---------
    def view_path
      File.join(File.dirname(__FILE__), '..', 'views')
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