module WulinMaster
  class ExceptionReportController < ::ActionController::Metal
    def js_error
      e = Exceptions::JavascriptError.new(params[:message])
      ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
      self.response_body = [].to_json
    end
  end
end