class UserMailer < ActionMailer::Base

  def registration_confirmation(user, confirmation_url)
    recipients user.email
    from       APP_CONFIG.asi_mail_from_address
    subject    "OtaSizzle registration confirmation"
    body       :user => user, :confirmation_url => confirmation_url
  end

  def welcome(user, client)
    recipients user.email
    from APP_CONFIG.asi_mail_from_address
    subject "Tervetuloa #{client.realname || client.name}-käyttäjäksi! | Welcome to #{client.realname || client.name}!"
    body :user => user, :client => client
  end
  
  def recovery(options)
    recipients options[:email]
    from APP_CONFIG.asi_mail_from_address
    subject "OtaSizzle password recovery"
    content_type 'text/html'

    body :key => options[:key], :domain => options[:domain]
  end

end
