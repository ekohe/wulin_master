require File.join(File.dirname(__FILE__), 'panel_relation')

module WulinMaster
  class PanelView < ::ActionView::Base
    def protect_against_forgery?
      false
    end
  end

  class Panel < Component
    include PanelRelation

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
      attr_reader :partial, :title
      
      def init
        initialize_styles
        initialize_relations
      end

      def partial(new_partial=nil)
        new_partial ? @partial = new_partial : @partial
      end

      def title(new_title=nil)
        new_title ? @title = new_title : @title
      end
    end

    # Instance methods
    # --------------------
    def initialize(params={}, controller_instance=nil, config={})
      super
    end

    def name
      self.class.to_s.sub('Panel', '').sub('WulinMaster::', '').underscore
    end

    def partial
      self.class.partial || self.name
    end

    def title
      self.class.title
    end

    def view_paths
      # use application path first, then use wulin_master gem path
      [File.join(Rails.root, 'app', 'views', 'panel_partials'), File.join(File.dirname(__FILE__), "..", '..', '..', '..', 'app', 'views', 'panel_partials', 'wulin_master')]
    end
    
    def render
      partial_str = nil
      errors = []
      view_paths.each do |path|
        begin
          partial_str = PanelView.new(path).render(:partial => "#{partial}", :locals => {:panel => self})
          break
        rescue Exception => e
          errors << e.try(:message)
          next
        end
      end
      partial_str || (raise errors.join(", "))
    end

  end
end