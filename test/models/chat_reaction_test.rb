require "test_helper"

class ChatReactionTest < ActiveSupport::TestCase
  def admin
    @admin ||= User.create!(
      email_address: "cr-admin-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :admin,
      email_verified_at: 1.day.ago
    )
  end

  def other
    @other ||= User.create!(
      email_address: "cr-other-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :editor,
      email_verified_at: 1.day.ago
    )
  end

  def channel
    @channel ||= ChatChannel.create!(name: "cr-ch-#{SecureRandom.hex(4)}", created_by: admin)
  end

  def message
    @message ||= ChatMessage.create!(chat_channel: channel, author: admin, body: "React me")
  end

  test "valid reaction" do
    r = ChatReaction.new(chat_message: message, user: admin, emoji: "👍")
    assert r.valid?
  end

  test "requires emoji" do
    r = ChatReaction.new(chat_message: message, user: admin, emoji: "")
    assert_not r.valid?
  end

  test "unique per user per emoji per message" do
    ChatReaction.create!(chat_message: message, user: admin, emoji: "👍")
    duplicate = ChatReaction.new(chat_message: message, user: admin, emoji: "👍")
    assert_not duplicate.valid?
  end

  test "same emoji from different users is allowed" do
    ChatReaction.create!(chat_message: message, user: admin, emoji: "👍")
    other_reaction = ChatReaction.new(chat_message: message, user: other, emoji: "👍")
    assert other_reaction.valid?
  end

  test "same user can react with different emojis" do
    ChatReaction.create!(chat_message: message, user: admin, emoji: "👍")
    second = ChatReaction.new(chat_message: message, user: admin, emoji: "❤️")
    assert second.valid?
  end
end
