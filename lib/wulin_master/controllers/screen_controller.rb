module WulinMaster
  class ScreenController < ::ApplicationController
    self.view_paths = [File.join(Rails.root, 'app', 'views'), File.join(File.dirname(__FILE__), '..', 'views')]

    def self.controller_for_screen(klass)
      @screen = klass
      load_actions
    end

    def self.controller_for_grid(name)
      @grid = Grid.get(name)
      @grid.controller_class = self if @grid
      @callbacks = {}
      load_actions
    end

    def self.index_path
      "/#{self.to_s.underscore.downcase.gsub(/_controller/, '')}"
    end

    def self.screen
      @screen
    end

    def screen
      self.class.screen
    end

    def self.grid
      @grid
    end

    def grid
      self.class.grid
    end

    def render_grid(grid_name)
      return "Grid not found '#{grid_name}'" unless screen.grids.map(&:name).include?(grid_name.to_sym)
      grid = screen.grids.find {|grid| grid.name == grid_name}
      grid.render
    end

    # Callbacks
    #

    def add_callback(name, method_name=nil)
      @callbacks ||= {}
      @callbacks[name] ||= []
      if block_given?
        @callbacks[name] << lambda { yield }
      else
        @callbacks[name] << method_name
      end
    end

    def fire_callbacks(name)
      return unless callbacks
      cbs = callbacks(name)

      return if cbs.blank?
      cbs.each do |cb|
        if cb.class == Proc
          cb.call
        else
          self.send(cb) if self.respond_to?(cb)
        end
      end
    end

    def callbacks(name=nil)
      name ? @callbacks[name] : @callbacks
    end

    private

    # Load actions
    def self.load_actions
      self.send(:include, WulinMaster::Actions)
    end
  end
end

