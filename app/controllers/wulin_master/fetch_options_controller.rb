require 'wulin_master/utilities/variables'
module WulinMaster
  class FetchOptionsController < ::ActionController::Metal
    FORBIDDENMESSAGE = "Sorry you can't get anything, please contact administrator."

    def index
      if authorized? and params[:text_attr].present?
        query = klass
        # dynamic filter
        if params[:master_model].present? and params[:master_id].present?
          reflection = klass.reflections[params[:master_model].to_sym] || klass.reflections[params[:master_model].pluralize.to_sym]
          query = query.where("#{reflection.foreign_key}=?", params[:master_id]).joins(reflection.name)
        end
        if klass.column_names.include? params[:text_attr]
          objects = query.select("id, #{params[:text_attr]}").order("#{params[:text_attr]} ASC").all
        else
          objects = query.all.sort{|x,y| x.send(params[:text_attr]).to_s.downcase <=> y.send(params[:text_attr]).to_s.downcase}
        end
        self.response_body = objects.collect{|o| {:id => o.id, params[:text_attr].to_sym => o.send(params[:text_attr])} }.to_json
      else
        self.status = 403
        self.response_body = FORBIDDENMESSAGE
      end
    rescue
      self.status = 500
      self.response_body = "Something wrong: #{$!.message}"
    end

    def specify_fetch
      if authorized? and params[:name_attr].present? and params[:code_attr].present?
        if klass.column_names.include?(params[:name_attr]) and klass.column_names.include?(params[:code_attr])
          objects = klass.select("id, #{params[:name_attr]}, #{params[:code_attr]}").order("#{params[:name_attr]} ASC")
        else
          objects = klass.all.sort{|x,y| x.send(params[:name_attr]).to_s.downcase <=> y.send(params[:name_attr]).to_s.downcase}
        end
        self.response_body = objects.to_json
      else
        self.status = 403
        self.response_body = FORBIDDENMESSAGE
      end
    rescue
      self.status = 500
      self.response_body = "Something wrong: #{$!.message}"
    end

    def fetch_distinct_options
      if authorized? and params[:text_attr].present?
        if params[:query_prefix]
          object_arr = klass.select(params[:text_attr]).where("lower(#{params[:text_attr]}) like ?", "#{params[:query_prefix].downcase}%").order("#{params[:text_attr]} ASC").uniq.pluck(params[:text_attr]).delete_if(&:blank?)
        else
          object_arr = klass.select(params[:text_attr]).order("#{params[:text_attr]} ASC").uniq.pluck(params[:text_attr]).delete_if(&:blank?)
        end
        self.response_body = object_arr.to_json
      else
        self.status = 403
        self.response_body = FORBIDDENMESSAGE
      end
    rescue
      self.status = 500
      self.response_body = "Something wrong: #{$!.message}"
    end

    private
      def authorized?
        return true unless self.respond_to?(:current_user)
        current_user && column_belongs_to_grid? && screen.authorized?(current_user)
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
