# frozen_string_literal: true

module WulinMaster
  class ScreenParamInvalidError < StandardError
    def initialize
      super "Can't find a proper screen for the controller"
    end
  end

  module Variables
    extend ActiveSupport::Concern

    def screen
      @screen ||= begin
        if params[:screen].present?
          if screen_class = params[:screen].classify.safe_constantize
            screen_class.new(self)
          else
            raise WulinMaster::ScreenParamInvalidError
          end
        else
          self.class.screen_classes.first.new(self)
        end
      end
    end

    def grid
      @grid ||= begin
        if params[:grid]
          screen.grids.find { |grid| grid.class.name == params[:grid] }
        else
          screen.grids.find { |grid| grid.model.model_name.plural == controller_name }
        end || screen.grids.first
      end
    end

    def components
      @components ||= screen.components
    end
  end
end
