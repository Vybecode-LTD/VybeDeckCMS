require "test_helper"

class AiConversationTest < ActiveSupport::TestCase
  def create_user
    User.create!(
      email_address: "ai_user_#{SecureRandom.hex(4)}@test.com",
      password: "password1234",
      display_name: "AiUser#{SecureRandom.hex(4)}",
      role: :editor,
      email_verified_at: Time.current
    )
  end

  test "valid conversation" do
    convo = AiConversation.new(user: create_user, title: "Test")
    assert convo.valid?
  end

  test "requires user" do
    convo = AiConversation.new(title: "No user")
    assert_not convo.valid?
  end

  test "title defaults to empty string" do
    convo = AiConversation.create!(user: create_user)
    assert_equal "", convo.title
  end

  test "start_for creates conversation with truncated title" do
    user  = create_user
    convo = AiConversation.start_for(user, "Write a blog post about summer vibes")
    assert convo.persisted?
    assert_includes convo.title, "Write a blog post"
  end

  test "recent scope orders by created_at desc" do
    user = create_user
    c1   = AiConversation.create!(user: user, title: "First")
    c2   = AiConversation.create!(user: user, title: "Second")
    assert_equal [ c2, c1 ], AiConversation.where(user: user).recent.to_a
  end

  test "token totals sum assistant messages" do
    user  = create_user
    convo = AiConversation.create!(user: user)
    convo.ai_messages.create!(role: :user,      content: "Hello")
    convo.ai_messages.create!(role: :assistant, content: "Hi", input_tokens: 10, output_tokens: 20)
    assert_equal 10, convo.total_input_tokens
    assert_equal 20, convo.total_output_tokens
  end
end
