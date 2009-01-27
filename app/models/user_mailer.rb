class UserMailer < ActionMailer::Base

  def registration_confirmation(user, key)
    recipients user.email
    from       COS_MAIL_FROM_ADRESS
    subject    "OtaSizzle registration confirmation"
    body       :user => user, :key => key, :confirmation_url => "example.com/root_url"
  end

end
