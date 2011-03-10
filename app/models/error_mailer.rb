class ErrorMailer < ActionMailer::Base
  default :from => APP_CONFIG.error_mailer_from_address

  def snapshot(exception, trace, session, params, request, current_user, sent_on = Time.now)
    @exception = exception
    @trace = trace,
    @session = session
    @params = params,
    @request = request
    @current_user = current_user
    @sent_on = sent_on

    mail(:to => APP_CONFIG.error_mailer_recipients,
         :subject => "[Error] exception on #{request.url}")

 end

end
