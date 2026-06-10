require "test_helper"

# Phase 5 — Admin Group Chat integration tests.
#
# Covers auth gates, channel create/show, message send/edit/delete, reaction toggle,
# private channel access control, and member exclusion.
class AdminChatTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address: "chat-int-admin-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :admin,
      email_verified_at: 1.day.ago
    )
    @editor = User.create!(
      email_address: "chat-int-editor-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :editor,
      email_verified_at: 1.day.ago
    )
    @member = User.create!(
      email_address: "chat-int-member-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :member,
      email_verified_at: 1.day.ago
    )

    @channel = ChatChannel.create!(
      name: "general-#{SecureRandom.hex(4)}",
      created_by: @admin
    )
    @private_channel = ChatChannel.create!(
      name: "private-#{SecureRandom.hex(4)}",
      is_private: true,
      created_by: @admin
    )
    @message = ChatMessage.create!(
      chat_channel: @channel,
      author: @admin,
      body: "Hello team"
    )
  end

  # ── Auth gates ───────────────────────────────────────────────────────────────

  test "anonymous user is redirected to sign-in" do
    get admin_chat_path
    assert_redirected_to new_session_path
  end

  test "member cannot access chat" do
    sign_in_as @member
    get admin_chat_path
    assert_redirected_to root_path
  end

  # ── Admin access ─────────────────────────────────────────────────────────────

  test "admin can view chat index" do
    sign_in_as @admin
    get admin_chat_path
    assert_response :ok
  end

  test "admin can view specific channel" do
    sign_in_as @admin
    get admin_chat_channel_path(@channel)
    assert_response :ok
    assert_match "Hello team", response.body
  end

  test "editor can view public channel" do
    sign_in_as @editor
    get admin_chat_channel_path(@channel)
    assert_response :ok
  end

  # ── Private channel access control ──────────────────────────────────────────

  test "editor cannot view private channel" do
    sign_in_as @editor
    get admin_chat_channel_path(@private_channel)
    assert_redirected_to root_path
  end

  test "admin can view private channel" do
    sign_in_as @admin
    get admin_chat_channel_path(@private_channel)
    assert_response :ok
  end

  # ── Channel creation ─────────────────────────────────────────────────────────

  test "admin can create a channel" do
    sign_in_as @admin
    assert_difference "ChatChannel.count" do
      post admin_chat_channels_path,
           params: { chat_channel: { name: "new-ch-#{SecureRandom.hex(4)}", is_private: false } }
    end
    assert_response :redirect
  end

  test "editor cannot create a channel" do
    sign_in_as @editor
    assert_no_difference "ChatChannel.count" do
      post admin_chat_channels_path,
           params: { chat_channel: { name: "editor-ch-#{SecureRandom.hex(4)}" } }
    end
    assert_redirected_to root_path
  end

  # ── Message creation ─────────────────────────────────────────────────────────

  test "admin can post a message" do
    sign_in_as @admin
    assert_difference "ChatMessage.count" do
      post admin_chat_channel_messages_path(channel_id: @channel.id),
           params: { chat_message: { body: "New message" } }
    end
    assert_response :ok
  end

  test "editor can post a message" do
    sign_in_as @editor
    assert_difference "ChatMessage.count" do
      post admin_chat_channel_messages_path(channel_id: @channel.id),
           params: { chat_message: { body: "Editor message" } }
    end
    assert_response :ok
  end

  test "member cannot post a message" do
    sign_in_as @member
    assert_no_difference "ChatMessage.count" do
      post admin_chat_channel_messages_path(channel_id: @channel.id),
           params: { chat_message: { body: "Member message" } }
    end
    assert_redirected_to root_path
  end

  # ── Message edit ─────────────────────────────────────────────────────────────

  test "author can edit own message" do
    sign_in_as @admin
    patch admin_chat_channel_message_path(channel_id: @channel.id, id: @message.id),
          params: { chat_message: { body: "Edited body" } }
    assert_response :ok
    assert_equal "Edited body", @message.reload.body
    assert_not_nil @message.reload.edited_at
  end

  test "editor cannot edit admin message" do
    sign_in_as @editor
    patch admin_chat_channel_message_path(channel_id: @channel.id, id: @message.id),
          params: { chat_message: { body: "Hijacked" } }
    assert_redirected_to root_path
    assert_equal "Hello team", @message.reload.body
  end

  test "admin can edit any message" do
    editor_msg = ChatMessage.create!(chat_channel: @channel, author: @editor, body: "Editor post")
    sign_in_as @admin
    patch admin_chat_channel_message_path(channel_id: @channel.id, id: editor_msg.id),
          params: { chat_message: { body: "Admin edit" } }
    assert_response :ok
    assert_equal "Admin edit", editor_msg.reload.body
  end

  # ── Message delete (soft) ────────────────────────────────────────────────────

  test "author can soft-delete own message" do
    sign_in_as @admin
    delete admin_chat_channel_message_path(channel_id: @channel.id, id: @message.id)
    assert_response :ok
    assert @message.reload.deleted?
  end

  test "editor cannot delete admin message" do
    sign_in_as @editor
    delete admin_chat_channel_message_path(channel_id: @channel.id, id: @message.id)
    assert_redirected_to root_path
    assert_not @message.reload.deleted?
  end

  # ── Reaction toggle ──────────────────────────────────────────────────────────

  test "admin can add a reaction" do
    sign_in_as @admin
    assert_difference "ChatReaction.count" do
      post admin_chat_reaction_path(channel_id: @channel.id, message_id: @message.id),
           params: { chat_reaction: { emoji: "👍" } }
    end
    assert_response :ok
  end

  test "posting same emoji toggles it off" do
    ChatReaction.create!(chat_message: @message, user: @admin, emoji: "👍")
    sign_in_as @admin
    assert_difference "ChatReaction.count", -1 do
      post admin_chat_reaction_path(channel_id: @channel.id, message_id: @message.id),
           params: { chat_reaction: { emoji: "👍" } }
    end
    assert_response :ok
  end

  test "member cannot react" do
    sign_in_as @member
    assert_no_difference "ChatReaction.count" do
      post admin_chat_reaction_path(channel_id: @channel.id, message_id: @message.id),
           params: { chat_reaction: { emoji: "👍" } }
    end
    assert_redirected_to root_path
  end
end
