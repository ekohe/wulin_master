module WulinMaster
  class Menu < Array
  
    # Rendering
    # ----------
    def view_path
      File.join(File.dirname(__FILE__), '..', 'views')
    end
  
    # Satisfy render_to_string
    def action_name
      ""
    end
  
    # Render the menu
    def render
      ActionView::Base.new(view_path).render(:partial => "menu", :locals => {:menu => self})
    end
  end

  class MenuEntry
    attr_reader :title, :path
  
    def initialize(title, path)
      @title = title
      @path = path
    end
  
    def is_submenu?
      false
    end
  end

  class SubMenu < Menu
    attr_reader :title
  
    def initialize(title)
      @title = title
    end

    def is_submenu?
      true
    end
  end
end