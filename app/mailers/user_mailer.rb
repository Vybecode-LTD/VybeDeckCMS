class UserMailer < ApplicationMailer
  # Sends a one-time email verification link.
  # The token is passed explicitly so the job has the raw value before it is
  # hashed or rotated by a later call.
  def email_verification(user, token)
    @user  = user
    @url   = verify_email_registration_url(token: token)
    mail(to: @user.email_address, subject: "Verify your VybeDeck CMS email address")
  end
end
