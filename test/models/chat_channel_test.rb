require "test_helper"

class ChatChannelTest < ActiveSupport::TestCase
  def admin
    @admin ||= User.create!(
      email_address: "chat-admin-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :admin,
      email_verified_at: 1.day.ago
    )
  end

  def build_channel(overrides = {})
    ChatChannel.new({ name: "test-#{SecureRandom.hex(4)}", is_private: false, created_by: admin }.merge(overrides))
  end

  test "valid public channel" do
    assert build_channel.valid?
  end

  test "valid private channel" do
    assert build_channel(is_private: true).valid?
  end

  test "requires name" do
    ch = build_channel(name: "")
    assert_not ch.valid?
    assert ch.errors[:name].any?
  end

  test "name must be unique" do
    name = "unique-#{SecureRandom.hex(4)}"
    build_channel(name: name).save!
    duplicate = build_channel(name: name)
    assert_not duplicate.valid?
    assert duplicate.errors[:name].any?
  end

  test "name length limit 80 chars" do
    ch = build_channel(name: "x" * 81)
    assert_not ch.valid?
  end

  test "is_private defaults false" do
    ch = ChatChannel.new(name: "test-#{SecureRandom.hex(4)}", created_by: admin)
    ch.valid?
    assert_equal false, ch.is_private
  end

  test "has_many chat_messages" do
    ch = build_channel
    ch.save!
    assert_respond_to ch, :chat_messages
  end
end
