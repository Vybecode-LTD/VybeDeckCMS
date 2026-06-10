require "test_helper"

class StreamAiResponseJobTest < ActiveJob::TestCase
  def setup
    @user = User.create!(
      email_address: "ai_job_test@test.com",
      password:      "password1234",
      display_name:  "AI Job Tester",
      role:          :admin,
      email_verified_at: Time.current
    )
    @conversation = AiConversation.create!(user: @user, title: "Test")
    @conversation.ai_messages.create!(role: :user, content: "Hello")
    @assistant = @conversation.ai_messages.create!(
      role: :assistant, content: "", streaming: true
    )
  end

  test "job completes with error content when API key is absent" do
    with_env("ANTHROPIC_API_KEY" => nil) do
      StreamAiResponseJob.perform_now(@assistant.id)
    end

    @assistant.reload
    assert_not @assistant.streaming?
    assert_match "not configured", @assistant.content
  end

  test "job is a no-op for a non-streaming message" do
    non_streaming = @conversation.ai_messages.create!(
      role: :assistant, content: "Already done", streaming: false
    )
    original_content = non_streaming.content

    StreamAiResponseJob.perform_now(non_streaming.id)

    assert_equal original_content, non_streaming.reload.content
  end

  test "job is a no-op for a missing message ID" do
    assert_nothing_raised do
      StreamAiResponseJob.perform_now(999_999)
    end
  end

  test "job marks message streaming false and saves content on success" do
    # Patch call_streaming_api on the job instance so no real HTTP call is made.
    original = StreamAiResponseJob.instance_method(:call_streaming_api)
    StreamAiResponseJob.define_method(:call_streaming_api) do |history, &block|
      block.call("Hello")
      block.call(", world!")
      { input_tokens: 10, output_tokens: 4 }
    end

    StreamAiResponseJob.perform_now(@assistant.id)

    @assistant.reload
    assert_equal "Hello, world!", @assistant.content
    assert_not   @assistant.streaming?
    assert_equal 10, @assistant.input_tokens
    assert_equal 4,  @assistant.output_tokens
  ensure
    StreamAiResponseJob.define_method(:call_streaming_api, original)
  end

  private

  def with_env(vars)
    saved = vars.each_with_object({}) { |(k, _), h| h[k.to_s] = ENV[k.to_s] }
    vars.each { |k, v| v.nil? ? ENV.delete(k.to_s) : ENV[k.to_s] = v.to_s }
    yield
  ensure
    saved.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
