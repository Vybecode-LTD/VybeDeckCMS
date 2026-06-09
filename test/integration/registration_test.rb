require "test_helper"

class RegistrationTest < ActionDispatch::IntegrationTest
  setup do
    SiteSetting.delete_all  # start each test from a clean settings state
    ActionMailer::Base.deliveries.clear
  end

  teardown do
    SiteSetting.delete_all
    ActionMailer::Base.deliveries.clear
  end

  # ── GET /register ─────────────────────────────────────────────────────────────

  test "registration form is accessible when invite_only is off" do
    get new_registration_path
    assert_response :ok
    assert_select "form[action='#{registrations_path}']"
  end

  test "registration form is forbidden when invite_only is on" do
    SiteSetting.set("invite_only", "true")
    get new_registration_path
    assert_response :forbidden
  end

  test "authenticated user is redirected away from registration form" do
    user = verified_user
    sign_in_as user
    get new_registration_path
    assert_redirected_to root_path
  end

  # ── POST /register ────────────────────────────────────────────────────────────

  test "successful registration creates an unverified author user" do
    assert_difference "User.count", 1 do
      post registrations_path, params: {
        user: {
          email_address:         "newuser-#{SecureRandom.hex(4)}@test.com",
          password:              "securepassword123",
          password_confirmation: "securepassword123"
        }
      }
    end

    new_user = User.order(:created_at).last
    assert new_user.author?
    assert_not new_user.email_verified?
    assert new_user.email_verification_token.present?
  end

  test "successful registration redirects to verify_email page" do
    post registrations_path, params: {
      user: {
        email_address:         "newuser-#{SecureRandom.hex(4)}@test.com",
        password:              "securepassword123",
        password_confirmation: "securepassword123"
      }
    }
    assert_redirected_to verify_email_registration_path
  end

  test "successful registration enqueues a verification email job" do
    assert_enqueued_with(job: SendEmailVerificationJob) do
      post registrations_path, params: {
        user: {
          email_address:         "newuser-#{SecureRandom.hex(4)}@test.com",
          password:              "securepassword123",
          password_confirmation: "securepassword123"
        }
      }
    end
  end

  test "verification email is delivered when the job runs" do
    user  = unverified_user
    token = user.generate_email_verification_token!

    assert_emails 1 do
      SendEmailVerificationJob.perform_now(user.id, token)
    end

    mail = ActionMailer::Base.deliveries.last
    assert_includes mail.subject, "Verify"
    assert_includes mail.to,      user.email_address
  end

  test "registration is blocked when invite_only is on" do
    SiteSetting.set("invite_only", "true")
    assert_no_difference "User.count" do
      post registrations_path, params: {
        user: {
          email_address:         "newuser-#{SecureRandom.hex(4)}@test.com",
          password:              "securepassword123",
          password_confirmation: "securepassword123"
        }
      }
    end
    assert_response :forbidden
  end

  test "registration fails with duplicate email" do
    existing = verified_user
    assert_no_difference "User.count" do
      post registrations_path, params: {
        user: {
          email_address:         existing.email_address,
          password:              "securepassword123",
          password_confirmation: "securepassword123"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "registration fails when passwords do not match" do
    assert_no_difference "User.count" do
      post registrations_path, params: {
        user: {
          email_address:         "newuser-#{SecureRandom.hex(4)}@test.com",
          password:              "securepassword123",
          password_confirmation: "differentpassword123"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "registration cannot set role to admin via params" do
    post registrations_path, params: {
      user: {
        email_address:         "newuser-#{SecureRandom.hex(4)}@test.com",
        password:              "securepassword123",
        password_confirmation: "securepassword123",
        role:                  "admin"
      }
    }
    new_user = User.order(:created_at).last
    assert new_user.author?, "expected newly registered user to be author, got #{new_user.role}"
  end

  # ── GET /register/verify?token= ───────────────────────────────────────────────

  test "valid token verifies the user and signs them in" do
    user  = unverified_user
    token = user.generate_email_verification_token!

    get verify_email_registration_path, params: { token: token }

    user.reload
    assert user.email_verified?, "expected user to be verified"
    assert_nil user.email_verification_token
    assert_redirected_to settings_path
  end

  test "visiting verify page without a token shows the holding page" do
    get verify_email_registration_path
    assert_response :ok
    assert_select "h1", text: /check your inbox/i
  end

  test "invalid token shows an error" do
    get verify_email_registration_path, params: { token: "not-a-real-token" }
    assert_response :unprocessable_entity
  end

  test "expired token shows an error and offers resend" do
    user  = unverified_user
    token = user.generate_email_verification_token!
    # Back-date sent_at past the 48-hour window
    user.update_columns(email_verification_sent_at: 49.hours.ago)

    get verify_email_registration_path, params: { token: token }

    assert_response :unprocessable_entity
    assert_select "form[action='#{resend_verification_registration_path}']"
  end

  test "already-used token returns invalid-or-used error" do
    user  = unverified_user
    token = user.generate_email_verification_token!
    user.verify_email!  # consume the token

    get verify_email_registration_path, params: { token: token }

    assert_response :unprocessable_entity
  end

  # ── POST /register/resend ─────────────────────────────────────────────────────

  test "resend enqueues a verification job for an unverified user" do
    user = unverified_user
    assert_enqueued_with(job: SendEmailVerificationJob) do
      post resend_verification_registration_path, params: { email: user.email_address }
    end
  end

  test "resend always redirects with the same notice (prevents email enumeration)" do
    post resend_verification_registration_path, params: { email: "nobody@example.com" }
    assert_redirected_to verify_email_registration_path
    # No error about unknown address
    follow_redirect!
    assert_match(/if that address/i, flash[:notice])
  end

  test "resend does not enqueue a job for already-verified users" do
    user = verified_user
    assert_no_enqueued_jobs(only: SendEmailVerificationJob) do
      post resend_verification_registration_path, params: { email: user.email_address }
    end
  end

  # ── sign-in gate ─────────────────────────────────────────────────────────────

  test "unverified user cannot sign in" do
    user = unverified_user

    post session_path, params: { email_address: user.email_address, password: "securepassword123" }

    assert_redirected_to verify_email_registration_path
    assert_nil Current.user
  end

  test "verified user can sign in normally" do
    user = verified_user

    post session_path, params: { email_address: user.email_address, password: "securepassword123" }

    assert_redirected_to root_path
  end

  private

  def unverified_user
    User.create!(
      email_address: "unverified-#{SecureRandom.hex(4)}@test.com",
      password:      "securepassword123",
      role:          :author
      # email_verified_at intentionally left nil
    )
  end

  def verified_user
    User.create!(
      email_address:   "verified-#{SecureRandom.hex(4)}@test.com",
      password:        "securepassword123",
      role:            :author,
      email_verified_at: Time.current
    )
  end
end
