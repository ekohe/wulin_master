module WulinMaster
  class ExceptionReportController < ::ActionController::Metal
    def js_error
      if Module.const_defined?('Rails') && Rails.env.production?
        e = Exceptions::JavascriptError.new(params[:message])
        ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
      end
      self.response_body = [].to_json
    end
  end
end
