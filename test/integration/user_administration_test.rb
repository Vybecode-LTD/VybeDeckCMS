require "test_helper"

# Integration tests for Phase 2.4: ban/unban, impersonation (Login-as), and bulk role.
class UserAdministrationTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address:     "admin-#{SecureRandom.hex(4)}@test.com",
      password:          "securepassword123",
      role:              :admin,
      email_verified_at: Time.current
    )
    @editor = User.create!(
      email_address:     "editor-#{SecureRandom.hex(4)}@test.com",
      password:          "securepassword123",
      role:              :editor,
      email_verified_at: Time.current
    )
    @member = User.create!(
      email_address:     "member-#{SecureRandom.hex(4)}@test.com",
      password:          "securepassword123",
      role:              :member,
      email_verified_at: Time.current
    )
  end

  # ── User list ─────────────────────────────────────────────────────────────

  test "admin can access the user list" do
    sign_in_as @admin
    get admin_users_path
    assert_response :ok
  end

  test "editor can access the user list" do
    sign_in_as @editor
    get admin_users_path
    assert_response :ok
  end

  test "member cannot access the user list" do
    sign_in_as @member
    get admin_users_path
    assert_redirected_to root_path
  end

  # ── Ban / Unban ────────────────────────────────────────────────────────────

  test "admin can ban a user" do
    sign_in_as @admin
    patch ban_admin_user_path(@member)
    @member.reload
    assert @member.banned?, "expected member to be banned"
    assert_redirected_to admin_user_path(@member)
  end

  test "admin can unban a banned user" do
    @member.ban!
    sign_in_as @admin
    patch unban_admin_user_path(@member)
    @member.reload
    assert_not @member.banned?, "expected member to be unbanned"
  end

  test "editor cannot ban a user" do
    sign_in_as @editor
    patch ban_admin_user_path(@member)
    @member.reload
    assert_not @member.banned?, "editor should not be able to ban"
  end

  test "banned user cannot sign in — receives same error as wrong password" do
    @member.ban!
    post session_path, params: {
      email_address: @member.email_address,
      password:      "securepassword123"
    }
    assert_redirected_to new_session_path
    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "unbanned user can sign in normally" do
    @member.ban!
    @member.unban!
    post session_path, params: {
      email_address: @member.email_address,
      password:      "securepassword123"
    }
    assert_redirected_to root_path
  end

  # ── Impersonation ─────────────────────────────────────────────────────────

  test "admin can start impersonating a member" do
    sign_in_as @admin
    post impersonate_admin_user_path(@member)
    assert_redirected_to root_path
    assert_match(/impersonating/i, flash[:notice])
  end

  test "impersonation creates an audit log entry" do
    sign_in_as @admin
    assert_difference "ImpersonationLog.count", 1 do
      post impersonate_admin_user_path(@member)
    end
    log = ImpersonationLog.last
    assert_equal @admin.id, log.impersonator_id
    assert_equal @member.id, log.impersonated_id
    assert log.active?
  end

  test "while impersonating, member cannot access admin" do
    sign_in_as @admin
    post impersonate_admin_user_path(@member)
    follow_redirect!

    # Now acting as @member — admin should be inaccessible
    get admin_root_path
    assert_redirected_to root_path
    assert_equal "You are not authorized to access the admin.", flash[:alert]
  end

  test "exiting impersonation closes the audit log entry" do
    sign_in_as @admin
    post impersonate_admin_user_path(@member)

    log = ImpersonationLog.last
    assert log.active?

    delete admin_impersonation_path
    log.reload
    assert_not log.active?, "audit log should be closed after exiting impersonation"
    assert_not_nil log.ended_at
  end

  test "exiting impersonation redirects to admin user list" do
    sign_in_as @admin
    post impersonate_admin_user_path(@member)
    delete admin_impersonation_path
    assert_redirected_to admin_users_path
  end

  test "after exiting impersonation, admin regains admin access" do
    sign_in_as @admin
    post impersonate_admin_user_path(@member)
    delete admin_impersonation_path
    follow_redirect!

    get admin_root_path
    assert_response :ok
  end

  test "admin cannot impersonate another admin" do
    other_admin = User.create!(
      email_address: "other-admin-#{SecureRandom.hex(4)}@test.com",
      password:      "securepassword123",
      role:          :admin
    )
    sign_in_as @admin
    post impersonate_admin_user_path(other_admin)
    # Pundit should block this — redirected with alert
    assert_redirected_to root_path
    assert_match(/not authorized/i, flash[:alert])
    # No impersonation log should be created
    assert_equal 0, ImpersonationLog.count
  end

  test "editor cannot impersonate users" do
    sign_in_as @editor
    post impersonate_admin_user_path(@member)
    # editor is not admin, Pundit blocks
    assert_redirected_to root_path
    assert_match(/not authorized/i, flash[:alert])
  end

  # ── Bulk role assignment ───────────────────────────────────────────────────

  test "admin can bulk-assign roles to selected users" do
    extra = User.create!(
      email_address: "extra-#{SecureRandom.hex(4)}@test.com",
      password:      "password",
      role:          :member
    )
    sign_in_as @admin
    patch bulk_role_admin_users_path, params: {
      user_ids: [ @member.id, extra.id ],
      role:     "subscriber"
    }
    assert_redirected_to admin_users_path
    assert @member.reload.subscriber?,  "expected member to become subscriber"
    assert extra.reload.subscriber?,     "expected extra to become subscriber"
  end

  test "bulk role with no users selected shows an alert" do
    sign_in_as @admin
    patch bulk_role_admin_users_path, params: { role: "author" }
    assert_redirected_to admin_users_path
    assert_match(/no users selected/i, flash[:alert])
  end

  test "bulk role with invalid role shows an alert" do
    sign_in_as @admin
    patch bulk_role_admin_users_path, params: {
      user_ids: [ @member.id ],
      role:     "supervillain"
    }
    assert_redirected_to admin_users_path
    assert_match(/invalid role/i, flash[:alert])
  end

  test "editor cannot bulk-assign roles" do
    sign_in_as @editor
    patch bulk_role_admin_users_path, params: {
      user_ids: [ @member.id ],
      role:     "author"
    }
    @member.reload
    assert @member.member?, "editor should not be able to change roles"
  end
end
