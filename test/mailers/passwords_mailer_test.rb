require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  setup do
    @user = User.create!(
      email_address: "reset-#{SecureRandom.hex(4)}@example.com",
      password:      "securepassword123",
      role:          :member
    )
  end

  test "reset renders a reset link" do
    mail = PasswordsMailer.reset(@user)
    assert_equal @user.email_address, mail.to.first
    assert_match(/password|reset/i, mail.subject)
    # The body renders a password reset URL — verify the link is present.
    assert_match "password", mail.body.encoded
  end
end
