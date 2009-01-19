class UserMailer < ActionMailer::Base

  def registration_confirmation(user)
    recipients user.email
    from       "support@sizl.org"
    subject    "OtaSizzle registration confirmation"
    body       :user => user
  end

end
