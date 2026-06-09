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

  test "editor cannot destroy a page (admin only)" do
    page = Page.create!(title: "To Delete", status: :draft)
    sign_in_as @editor
    delete admin_page_path(page)
    assert_response :redirect
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    assert Page.exists?(page.id)
  end

  test "admin can destroy a page" do
    page = Page.create!(title: "To Delete Admin", status: :draft)
    sign_in_as @admin
    assert_difference "Page.count", -1 do
      delete admin_page_path(page)
    end
  end

  test "editor cannot destroy a medium (admin only)" do
    medium = Medium.new(title: "test file", file_type: :image, uploaded_by: @editor)
    medium.file.attach(io: StringIO.new("fake"), filename: "test.png", content_type: "image/png")
    medium.save!
    sign_in_as @editor
    delete admin_medium_path(medium)
    assert_response :redirect
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    assert Medium.exists?(medium.id)
  end

  test "admin can destroy a medium" do
    medium = Medium.new(title: "admin file", file_type: :image, uploaded_by: @admin)
    medium.file.attach(io: StringIO.new("fake"), filename: "admin.png", content_type: "image/png")
    medium.save!
    sign_in_as @admin
    assert_difference "Medium.count", -1 do
      delete admin_medium_path(medium)
    end
  end

  test "admin series page loads" do
    sign_in_as @admin
    get admin_series_index_path
    assert_response :success
  end

  test "editor can access series admin" do
    sign_in_as @editor
    get admin_series_index_path
    assert_response :success
  end
end
