require 'wulin_master/utilities/variables'
module WulinMaster
  class FetchOptionsController < ::ActionController::Metal
    ForbiddenMessage = "Sorry you can't get anything, please contact administrator.".freeze

    def index
      if authorized? && params[:source].present?
        objects = if klass.column_names.include? params[:source]
          klass.select("id, #{params[:source]}").order("#{params[:source]} ASC").all
        else
          klass.all.sort { |x, y| x.send(params[:source]).to_s.downcase <=> y.send(params[:source]).to_s.downcase }
        end

        self.response_body = objects.collect { |o| {:id => o.id, params[:source].to_sym => o.send(params[:source])} }.to_json
      else
        self.status = 403
        self.response_body = ForbiddenMessage
      end
    rescue
      self.status = 500
      self.response_body = "Something wrong: #{$ERROR_INFO.message}"
    end

    def specify_fetch
      if authorized? && params[:name_attr].present? && params[:code_attr].present?
        objects = if klass.column_names.include?(params[:name_attr]) && klass.column_names.include?(params[:code_attr])
          klass.select("id, #{params[:name_attr]}, #{params[:code_attr]}").order("#{params[:name_attr]} ASC").all
        else
          klass.all.sort { |x, y| x.send(params[:name_attr]).to_s.downcase <=> y.send(params[:name_attr]).to_s.downcase }
        end
        self.response_body = objects.to_json
      else
        self.status = 403
        self.response_body = ForbiddenMessage
      end
    rescue
      self.status = 500
      self.response_body = "Something wrong: #{$ERROR_INFO.message}"
    end

    def fetch_distinct_options
      if authorized? && params[:source].present?
        object_arr = klass.select(params[:source]).order("#{params[:source]} ASC").distinct.pluck(params[:source]).delete_if(&:blank?)
        self.response_body = object_arr.to_json
      else
        self.status = 403
        self.response_body = ForbiddenMessage
      end
    rescue
      self.status = 500
      self.response_body = "Something wrong: #{$ERROR_INFO.message}"
    end

    private
    def authorized?
      return true unless respond_to?(:current_user)
      current_user && column_belongs_to_grid? && screen.authorized?(current_user)
    end

    def column_belongs_to_grid?
      !!column
    end

    def klass
      column.reflection.try(:klass) || params[:klass].classify.safe_constantize
    end

    def column
      grid.columns.find { |x| x.name.to_s == params[:column] }
    end

    def code_name_column?
      ['code', 'name'].include?(params[:source]) &&
        (['code', 'name'] & klass.column_names) == ['code', 'name']
    end
  end
end
