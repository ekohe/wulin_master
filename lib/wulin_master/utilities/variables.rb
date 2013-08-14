module WulinMaster
  module Variables
    def screen
      @screen ||= begin
        if params[:screen].present?
          if screen_class = params[:screen].classify.safe_constantize
            screen_class.new(self)
          else
            raise "Can't find a proper screen for the controller"
          end
        else
          self.class.screen_classes.first.new(self)
        end
      end
    end

    def grid
      @grid ||= begin
        if params[:grid]
          screen.grids.find {|grid| grid.class.name == params[:grid]}
        else
          screen.grids.find {|grid| grid.model.model_name.plural == controller_name}
        end || screen.grids.first
      end
    end

    def components
      @components ||= screen.components
    end
  end
end