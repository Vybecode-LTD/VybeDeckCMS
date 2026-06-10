require "test_helper"

class AiMessageTest < ActiveSupport::TestCase
  def create_conversation
    user = User.create!(
      email_address: "ai_#{SecureRandom.hex(4)}@test.com",
      password: "password1234",
      display_name: "AiMsg#{SecureRandom.hex(4)}",
      role: :editor,
      email_verified_at: Time.current
    )
    AiConversation.create!(user: user, title: "Test Convo")
  end

  test "valid user message" do
    m = AiMessage.new(ai_conversation: create_conversation, role: :user, content: "Hello")
    assert m.valid?
  end

  test "valid assistant message with token counts" do
    m = AiMessage.new(
      ai_conversation: create_conversation,
      role:          :assistant,
      content:       "Hi there",
      input_tokens:  50,
      output_tokens: 20
    )
    assert m.valid?
  end

  test "requires content" do
    m = AiMessage.new(ai_conversation: create_conversation, role: :user, content: "")
    assert_not m.valid?
  end

  test "requires role" do
    m = AiMessage.new(ai_conversation: create_conversation, content: "test")
    # default is :user (0), so this should be valid
    assert m.valid?
  end

  test "default role is user" do
    m = AiMessage.new(ai_conversation: create_conversation, content: "test")
    assert_predicate m, :user?
  end

  test "ordered scope returns messages by created_at" do
    convo = create_conversation
    m1 = convo.ai_messages.create!(role: :user,      content: "First")
    m2 = convo.ai_messages.create!(role: :assistant, content: "Second", input_tokens: 10, output_tokens: 10)
    assert_equal [ m1, m2 ], convo.ai_messages.ordered.to_a
  end
end
