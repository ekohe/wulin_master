module WulinMaster
  class ExceptionReportController < ::ActionController::Metal
    def js_error
      if Module.const_defined?('Rails') and Module.const_defined?('ExceptionNotifier') and Rails.env.production?
        e = Exceptions::JavascriptError.new(params[:message])
        ExceptionNotifier.notify_exception(e)
      end
      self.response_body = [].to_json
    end
  end
end
