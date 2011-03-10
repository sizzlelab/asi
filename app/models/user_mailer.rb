class UserMailer < ActionMailer::Base
  default :from => APP_CONFIG.asi_mail_from_address

  def registration_confirmation(user, confirmation_url)
    @user = user
    @confirmation_url = confirmation_url

    mail(:to => user.email,
         :subject => "OtaSizzle registration confirmation")
  end
    
  def welcome(user, client)
    @user = user
    @client = client

    mail(:to => user.email,
         :subject => "Tervetuloa #{client.realname || client.name}-käyttäjäksi! | Welcome to #{client.realname || client.name}!")
  end
  
  def recovery(options)
    @key = options[:key]
    @domain = options[:domain]

    mail(:to => options[:email],
         :subject => "OtaSizzle password recovery")
  end

end
