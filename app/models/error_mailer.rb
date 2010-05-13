class ErrorMailer < ActionMailer::Base

 def snapshot(exception, trace, session, params, request, current_user, sent_on = Time.now)

  # [nazgum]: Setting the content-type like this did not work for me
  #@headers["Content-Type"] = "text/html"

  # Setting the content-type like this does:
    content_type "text/html"


    recipients  APP_CONFIG.error_mailer_recipients
    from        APP_CONFIG.error_mailer_from_address
    subject     "[Error] exception on #{request.url}" #  #{env['REQUEST_URI']}"
    sent_on    sent_on
    body        :exception => exception, :trace => trace,
                :session => session, :params => params,
                :request => request, :current_user => current_user

 end

end
