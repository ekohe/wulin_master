require File.join(File.dirname(__FILE__), 'toolbar')
require File.join(File.dirname(__FILE__), 'toolbar_item')

module WulinMaster
  class Grid
    attr_reader :name
    attr_accessor :columns, :base_model, :controller_class, :toolbar

    @@grids = []
    @@default_toolbar_items = []

    # Class methods
    # -------------

    # Get a grid with its name
    def self.get(name)
      @@grids.find{|grid| grid.name == name}
    end

    def self.grids
      @@grids
    end

    # Default toolbar
    def self.add_to_default_toolbar(item, options={})
      if item.class == ToolbarItem
        @@default_toolbar_items << item
      elsif item.class == String
        @@default_toolbar_items << ToolbarItem.new(item, options)
      end
    end
    
    # Instance methods
    # --------------------
    def initialize(name)
      @name = name
      @columns = []
      @height = 400
      @width = 800
      @fill_window = false
      create_default_toolbar
      add_default_column
      @@grids.delete(Grid.get(name)) if Grid.get(name)
      @@grids << self
    end

    # Grid definition methods  
    def column(name, options={})
      @columns << Column.new(name, self, options)
    end
    
    def add_to_toolbar(item, options={})
      if item.class == ToolbarItem
        @toolbar << item
      elsif item.class == String
        @toolbar << ToolbarItem.new(item, options)
      end
    end

    def create_default_toolbar
      @toolbar = Toolbar.new
      @@default_toolbar_items.each {|item| add_to_toolbar(item) }
    end

    def add_default_column
      @columns << Column.new(:id, self, {:visible => false, :editable => false, :sortable => true})
    end

    # Helpers for SQL and Javascript generation
    # ----------

    def sql_columns
      @columns.map(&:name).map {|col| "#{col}"} # MSSQL specific
    end

    def sql_select
      sql_columns.join(",")
    end

    def apply_filter(query, column_name, filtering_value)
      column = @columns.find{|c| c.name.to_s == column_name.to_s}
      column.nil? ? query : column.apply_filter(query, filtering_value)
    end

    def arraify(objects)
      objects.collect do |object|
        @columns.collect {|col| {col.name => col.format(object.read_attribute(col.name.to_s))} }
      end
    end

    def javascript_column_model
      columns.collect(&:to_column_model).to_json
    end

    # Rendering
    # ----------
    def view_path
      File.join(File.dirname(__FILE__), '..', 'views')
    end

    # Satisfy render_to_string
    def action_name
      ""
    end

    # Render the grid
    def render
      ActionView::Base.new(view_path).render(:partial => "grid", :locals => {:grid => self})
    end

    def style_for_grid
      if fill_window?
        "position: absolute; top:59px; left:0; right:0; bottom:26px;"
      else
        "height: #{self.height}px; width: #{self.width}px;"
      end
    end

    def style_for_pager
      if fill_window?
        "position: absolute; left:0; right:0; bottom:0;"
      else
        "width: #{self.width}px"
      end
    end

    def style_for_header
      if fill_window?
        "position: absolute; top:0; left:0; right:0;"
      else
        "width: #{self.width}px"
      end
    end

    # Return the base model
    def model
      @base_model
    end

    # Return a title for the grid or set it up
    def title(new_title=nil)
      @title = new_title if new_title
      @title || name.to_s.humanize
    end

    def base_model(new_base_model=nil)
      @base_model = new_base_model if new_base_model
      @base_model
    end

    def path(new_path=nil)
      @path = new_path if new_path
      @path
    end

    def height(new_height=nil)
      @height = new_height if new_height
      @height
    end

    def width(new_width=nil)
      @width = new_width if new_width
      @width
    end

    def fill_window
      @fill_window = true
    end

    def fill_window?
      @fill_window==true
    end
  end
end

WulinMaster::Grid.add_to_default_toolbar "Filter", :class => 'filter_toggle', :icon => 'search'
