require File.join(File.dirname(__FILE__), 'toolbar')
require File.join(File.dirname(__FILE__), 'toolbar_item')

module WulinMaster
  class Grid
    attr_reader :name
    attr_accessor :columns, :base_model, :controller_class, :toolbar, :create_win_height, :create_win_width, :styles

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
      new_item = if item.class == ToolbarItem
        item
      elsif item.class == String
        ToolbarItem.new(item, options)
      end
      @@default_toolbar_items << new_item
    end

    # Instance methods
    # --------------------
    def initialize(name)
      @name = name
      @columns = []
      @height = 400
      @width = 800
      @fill_window = false
      @styles = ''
      create_default_toolbar
      add_default_column
      @@grids.delete(Grid.get(name)) if Grid.get(name)
      @@grids << self
    end

    def css(styles)
      @styles << styles.to_s
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
      @columns.map(&:name).map {|col| "#{col}"}
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
      @styles << "height: #{@height};"
      @height
    end

    def width(new_width=nil)
      @width = new_width if new_width
      @styles << "width: #{@width};"
      @width
    end

    def fill_window
      @fill_window = true
      @styles << "height: 100%; width: 100%; position: absolute; left:0; right:0;"
    end

    def fill_window?
      @fill_window==true
    end
  end
end

# Search action botton
WulinMaster::Grid.add_to_default_toolbar "Filter", :class => 'filter_toggle', :icon => 'search'

# Delete action button
WulinMaster::Grid.add_to_default_toolbar "Delete", :class => 'delete_button', :icon => 'delete_trash', :href => 'javascript: void(0);'

# Create action button
WulinMaster::Grid.add_to_default_toolbar "Add", :class => 'create_button', :icon => 'create', :href => 'javascript: void(0);'#, :before => 'Delete'
