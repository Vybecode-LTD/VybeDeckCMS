require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "byline returns display_name when set" do
    user = User.new(email_address: "user@test.com", password: "password", display_name: "Jane Doe")
    assert_equal "Jane Doe", user.byline
  end

  test "byline falls back to email_address when display_name is blank" do
    user = User.new(email_address: "user@test.com", password: "password")
    assert_equal "user@test.com", user.byline
  end
end
