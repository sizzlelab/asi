class ErrorMailer < ActionMailer::Base

 def snapshot(exception, trace, session, params, request, current_user, sent_on = Time.now)

  # [nazgum]: Setting the content-type like this did not work for me
  #@headers["Content-Type"] = "text/html"

  # Setting the content-type like this does:
    content_type "text/html"

  # @recipients   = 'gnomet@gmail.com'
  # @from     = 'Error Mailer <error @ domain.tld>'
  # @subject    = "[Error] exception in #{env['REQUEST_URI']}"
  # @sent_on    = sent_on
  # @body["exception"] = exception
  # @body["trace"]  = trace
  # @body["session"]  = session
  # @body["params"]  = params
  # @body["env"]   = env

    recipients  'vsundber@gmail.com'
    from        'Error Mailer <ASIErrors@sizl.org>'
    subject     "[Error] exception on #{SERVER_DOMAIN} at #{request.url}" #  #{env['REQUEST_URI']}"
    sent_on    sent_on
    body        :exception => exception, :trace => trace,
                :session => session, :params => params,
                :request => request, :current_user => current_user

 end

end
