require "test_helper"

class AdminAiTest < ActionDispatch::IntegrationTest
  def setup
    @admin  = create_user(role: :admin)
    @editor = create_user(role: :editor)
    @member = create_user(role: :member)
  end

  def create_user(role:)
    User.create!(
      email_address: "#{role}_#{SecureRandom.hex(4)}@test.com",
      password: "password1234",
      display_name: "#{role.to_s.capitalize}#{SecureRandom.hex(4)}",
      role: role,
      email_verified_at: Time.current
    )
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end

  # Streaming is async (Solid Queue job). These helpers are no longer needed
  # but kept as no-ops so existing tests that use them continue to work.
  def with_fake_ai_response(content: "Here is your response.", input: 10, output: 20)
    yield
  end

  # ── Auth gates ─────────────────────────────────────────────────────────────

  test "anonymous is redirected to login" do
    get admin_ai_path
    assert_redirected_to new_session_path
  end

  test "member cannot access AI assistant" do
    sign_in @member
    get admin_ai_path
    assert_redirected_to root_path
  end

  test "editor can access AI assistant" do
    sign_in @editor
    get admin_ai_path
    assert_response :success
  end

  test "admin can access AI assistant" do
    sign_in @admin
    get admin_ai_path
    assert_response :success
  end

  # ── Conversation creation ──────────────────────────────────────────────────

  test "editor can start a new conversation" do
    sign_in @editor
    assert_difference "AiConversation.count", 1 do
      post admin_ai_conversations_path, params: { content: "Draft a blog post about jazz" }
    end
    assert_response :redirect
    follow_redirect!
    assert_response :success
    # User message is shown immediately; assistant response streams in via job
    assert_match "Draft a blog post about jazz", response.body
  end

  test "blank message redirects with alert" do
    sign_in @editor
    assert_no_difference "AiConversation.count" do
      post admin_ai_conversations_path, params: { content: "" }
    end
    assert_redirected_to admin_ai_path
    assert_not_nil flash[:alert]
  end

  test "AI response is handled async — conversation always created on submit" do
    # In the streaming model, the conversation and a streaming placeholder are
    # created immediately; the actual API call (and any errors) happen in the
    # background job. No synchronous error flash on the create action.
    sign_in @editor
    assert_difference "AiConversation.count", 1 do
      post admin_ai_conversations_path, params: { content: "Hello" }
    end
    assert_redirected_to admin_ai_conversation_path(AiConversation.last)
  end

  # ── Message continuation ───────────────────────────────────────────────────

  test "editor can add a follow-up message" do
    sign_in @editor
    convo = AiConversation.create!(user: @editor, title: "Test")
    convo.ai_messages.create!(role: :user, content: "Hello")
    convo.ai_messages.create!(role: :assistant, content: "Hi", input_tokens: 5, output_tokens: 5)

    # Creates user message + streaming assistant placeholder (2 messages).
    # The actual API response is handled by StreamAiResponseJob asynchronously.
    assert_difference "AiMessage.count", 2 do
      post admin_ai_conversation_messages_path(convo), params: { content: "Tell me more" }
    end
    assert_redirected_to admin_ai_conversation_path(convo)
  end

  test "admin can delete a conversation" do
    sign_in @admin
    convo = AiConversation.create!(user: @admin, title: "To delete")
    assert_difference "AiConversation.count", -1 do
      delete admin_ai_conversation_path(convo)
    end
    assert_redirected_to admin_ai_path
  end

  test "editor cannot delete another user's conversation" do
    sign_in @editor
    convo = AiConversation.create!(user: @admin, title: "Admin's chat")
    assert_no_difference "AiConversation.count" do
      delete admin_ai_conversation_path(convo)
    end
    assert_redirected_to root_path
  end

  test "conversation show displays messages" do
    sign_in @editor
    convo = AiConversation.create!(user: @editor, title: "My Conversation")
    convo.ai_messages.create!(role: :user,      content: "What is SEO?")
    convo.ai_messages.create!(role: :assistant, content: "SEO stands for…", input_tokens: 10, output_tokens: 50)
    get admin_ai_conversation_path(convo)
    assert_response :success
    assert_match "What is SEO?",   response.body
    assert_match "SEO stands for", response.body
  end
end
