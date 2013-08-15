require 'wulin_master/utilities/variables'
module WulinMaster
  class FetchOptionsController < ::ActionController::Metal
    ForbiddenMessage = "Sorry you can't get anything, please contact administrator."

    def index
      if authorized? and params[:text_attr].present?
        if klass.column_names.include? params[:text_attr]
          objects = klass.select("id, #{params[:text_attr]}").order("#{params[:text_attr]} ASC").all
        else
          objects = klass.all.sort{|x,y| x.send(params[:text_attr]).to_s.downcase <=> y.send(params[:text_attr]).to_s.downcase}
        end
        self.response_body = objects.collect{|o| {:id => o.id, params[:text_attr].to_sym => o.send(params[:text_attr])} }.to_json
      else
        self.status = 403
        self.response_body = ForbiddenMessage
      end
    rescue
      self.status = 500
      self.response_body = "Something wrong: #{$!.message}"
    end

    def specify_fetch
      if authorized? and params[:name_attr].present? and params[:code_attr].present?
        if klass.column_names.include?(params[:name_attr]) and klass.column_names.include?(params[:code_attr])
          objects = klass.select("id, #{params[:name_attr]}, #{params[:code_attr]}").order("#{params[:name_attr]} ASC").all
        else
          objects = klass.all.sort{|x,y| x.send(params[:name_attr]).to_s.downcase <=> y.send(params[:name_attr]).to_s.downcase}
        end
        self.response_body = objects.to_json
      else
        self.status = 403
        self.response_body = ForbiddenMessage
      end
    rescue
      self.status = 500
      self.response_body = "Something wrong: #{$!.message}"
    end

    def fetch_distinct_options
      if authorized? and params[:text_attr].present?
        object_arr = klass.select(params[:text_attr]).order("#{params[:text_attr]} ASC").uniq.pluck(params[:text_attr]).delete_if(&:blank?)
        self.response_body = object_arr.to_json
      else
        self.status = 403
        self.response_body = ForbiddenMessage
      end
    rescue
      self.status = 500
      self.response_body = "Something wrong: #{$!.message}"
    end

    private
      def authorized?
        return true unless self.respond_to?(:current_user)
        current_user && column_belongs_to_grid? && screen.authorized?
      end

      def column_belongs_to_grid?
        !!column
      end

      def klass
        column.reflection.try(:klass) || params[:klass].classify.safe_constantize
      end

      def column
        grid.columns.find {|x| x.name.to_s == params[:column]}
      end

  end
end