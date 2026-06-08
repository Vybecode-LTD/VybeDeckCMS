require "test_helper"

class AdminAccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address: "admin-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :admin
    )
    @editor = User.create!(
      email_address: "editor-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :editor
    )
    @author = User.create!(
      email_address: "author-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :author
    )
  end

  test "anonymous visitor is redirected from admin to sign in" do
    get admin_root_path

    assert_redirected_to new_session_path
  end

  test "author is redirected away from admin" do
    sign_in_as @author

    get admin_root_path

    assert_redirected_to root_path
    assert_equal "You are not authorized to access the admin.", flash[:alert]
  end

  test "editor can access admin" do
    sign_in_as @editor

    get admin_root_path

    assert_response :success
  end

  test "admin can access admin" do
    sign_in_as @admin

    get admin_root_path

    assert_response :success
  end
end
