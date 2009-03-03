class UserMailer < ActionMailer::Base

  def registration_confirmation(user, confirmation_url)
    recipients user.email
    from       COS_MAIL_FROM_ADRESS
    subject    "OtaSizzle registration confirmation"
    body       :user => user, :confirmation_url => confirmation_url
  end

end
