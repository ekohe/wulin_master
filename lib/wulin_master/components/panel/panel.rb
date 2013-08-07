require 'wulin_master/components/panel/panel_relation'

module WulinMaster
  class Panel < Component
    include PanelRelation

    cattr_accessor :panels

    # Panel has been subclassed
    def self.inherited(klass)
      self.panels ||= []
      self.panels += [klass]
    end

    class << self
      attr_reader :partial, :title

      def partial(new_partial=nil)
        new_partial ? @partial = new_partial : @partial
      end

      def title(new_title=nil)
        new_title ? @title = new_title : @title
      end
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
  end
end