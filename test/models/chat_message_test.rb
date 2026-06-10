require "test_helper"

class ChatMessageTest < ActiveSupport::TestCase
  def admin
    @admin ||= User.create!(
      email_address: "cm-admin-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :admin,
      email_verified_at: 1.day.ago
    )
  end

  def channel
    @channel ||= ChatChannel.create!(name: "cm-ch-#{SecureRandom.hex(4)}", created_by: admin)
  end

  def build_message(overrides = {})
    ChatMessage.new({ chat_channel: channel, author: admin, body: "Hello" }.merge(overrides))
  end

  test "valid message with body" do
    assert build_message.valid?
  end

  test "requires body when no attachment" do
    msg = build_message(body: "")
    assert_not msg.valid?
    assert msg.errors[:body].any?
  end

  test "deleted? returns false by default" do
    assert_not build_message.deleted?
  end

  test "soft_delete! sets deleted_at" do
    msg = build_message
    msg.save!
    msg.soft_delete!
    assert msg.reload.deleted?
  end

  test "visible scope excludes soft-deleted" do
    msg = build_message
    msg.save!
    msg.soft_delete!
    assert_not_includes ChatMessage.visible, msg
  end

  test "visible scope includes non-deleted" do
    msg = build_message
    msg.save!
    assert_includes ChatMessage.visible, msg
  end

  test "recent scope orders ascending by created_at" do
    first  = build_message(body: "First")
    second = build_message(body: "Second")
    first.save!
    second.save!
    result = ChatMessage.recent.to_a
    assert result.index(first) < result.index(second)
  end
end
