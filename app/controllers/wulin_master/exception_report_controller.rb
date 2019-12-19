# frozen_string_literal: true

module WulinMaster
  class ExceptionReportController < ::ActionController::Metal
    def js_error
      if Module.const_defined?('Rails') && Module.const_defined?('ExceptionNotifier') && Rails.env.production?
        e = Exceptions::JavascriptError.new(params[:message])
        data = { js_stack: params[:stack] }
        ExceptionNotifier::Notifier.exception_notification(request.env, e, data: data).deliver
      end
      self.response_body = [].to_json
    end
  end
end
