module WulinMaster
  class Panel < Component
    cattr_accessor :panels

    # Panel has been subclassed
    def self.inherited(klass)
      self.panels ||= []
      self.panels << klass
      klass.init
    end

    # Class methods
    # -------------------
    class << self
      def init
        initialize_styles
      end
    end

    # Instance methods
    # --------------------
    def initialize(params={}, controller_instance=nil, config={})
      super
      apply_custom_config
    end

    def name
      self.class.to_s.sub('Panel', '').underscore
    end

    def view_paths
      # use application path first, then use wulin_master gem path
      [File.join(Rails.root, 'app', 'views', 'panel_partials'), File.join(File.dirname(__FILE__), "..", '..', '..', '..', 'app', 'views', 'panel_partials')]
    end
    
    def render
      partial_str = nil
      view_paths.each do |path|
        begin
          partial_str = ActionView::Base.new(path).render(:partial => "#{name}")
          break
        rescue
          next
        end
      end
      partial_str || (raise "Can't find panel partial #{name} in #{view_paths.join(', ')}")
    end

  end
end