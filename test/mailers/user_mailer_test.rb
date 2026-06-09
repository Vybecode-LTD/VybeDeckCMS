require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  setup do
    @user = User.create!(
      email_address:     "verify-#{SecureRandom.hex(4)}@example.com",
      password:          "securepassword123",
      role:              :member,
      email_verified_at: nil
    )
  end

  test "email_verification renders verification URL" do
    token = SecureRandom.urlsafe_base64(32)
    mail  = UserMailer.email_verification(@user, token)

    assert_equal @user.email_address, mail.to.first
    assert_match "Verify", mail.subject
    assert_match token, mail.body.encoded
  end
end
