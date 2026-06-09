require "test_helper"

class SendEmailVerificationJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  setup do
    @user = User.create!(
      email_address:     "verify-job-#{SecureRandom.hex(4)}@example.com",
      password:          "securepassword123",
      role:              :member,
      email_verified_at: nil
    )
  end

  test "delivers verification email for unverified user" do
    token = SecureRandom.urlsafe_base64(32)
    assert_emails 1 do
      SendEmailVerificationJob.perform_now(@user.id, token)
    end
  end

  test "skips already-verified user" do
    @user.update!(email_verified_at: Time.current)
    assert_emails 0 do
      SendEmailVerificationJob.perform_now(@user.id, "sometoken")
    end
  end

  test "skips deleted user" do
    assert_emails 0 do
      SendEmailVerificationJob.perform_now(0, "sometoken")
    end
  end
end
