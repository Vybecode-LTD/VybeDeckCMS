require "net/http"
require "uri"
require "json"

# Performs a streaming Anthropic API call for an AiMessage placeholder and
# broadcasts each chunk to the conversation's Turbo Stream channel.
class StreamAiResponseJob < ApplicationJob
  queue_as :default

  def perform(assistant_message_id)
    assistant = AiMessage.find_by(id: assistant_message_id)
    return unless assistant&.streaming?

    conversation = assistant.ai_conversation
    stream_key   = "ai_conversation_#{conversation.id}"

    # Build history from DB, excluding the blank placeholder itself.
    history = conversation.ai_messages
      .ordered
      .where.not(id: assistant.id)
      .map { |m| { role: m.role, content: m.content } }

    accumulated = ""

    result = call_streaming_api(history) do |chunk|
      accumulated += chunk
      Turbo::StreamsChannel.broadcast_replace_to(
        stream_key,
        target:  "ai-message-#{assistant.id}",
        partial: "admin/ai/message",
        locals:  { message: assistant, streaming_content: accumulated, streaming: true }
      )
    end

    if result[:error]
      final_content = "Error: #{result[:error]}"
      assistant.update!(content: final_content, streaming: false)
    else
      final_content = accumulated.presence || "(No response)"
      assistant.update!(
        content:       final_content,
        streaming:     false,
        input_tokens:  result[:input_tokens],
        output_tokens: result[:output_tokens]
      )
    end

    Turbo::StreamsChannel.broadcast_replace_to(
      stream_key,
      target:  "ai-message-#{assistant.id}",
      partial: "admin/ai/message",
      locals:  { message: assistant.reload, streaming: false }
    )
  end

  private

  def call_streaming_api(history, &block)
    api_key = ENV["ANTHROPIC_API_KEY"]
    return { error: "ANTHROPIC_API_KEY is not configured" } if api_key.blank?

    uri  = URI("https://api.anthropic.com/v1/messages")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl      = true
    http.read_timeout = 120

    req = Net::HTTP::Post.new(uri)
    req["Content-Type"]      = "application/json"
    req["x-api-key"]         = api_key
    req["anthropic-version"] = "2023-06-01"
    req.body = {
      model:      ENV.fetch("ANTHROPIC_MODEL", "claude-haiku-4-5-20251001"),
      max_tokens: 4096,
      system:     AiAssistantService::SYSTEM_PROMPT,
      stream:     true,
      messages:   history
    }.to_json

    input_tokens  = nil
    output_tokens = nil
    buffer        = ""

    http.request(req) do |response|
      response.read_body do |chunk|
        buffer += chunk
        while (line = buffer.slice!(/\A[^\n]*\n/))
          line.strip!
          next unless line.start_with?("data: ")
          data = line[6..]
          next if data == "[DONE]"
          begin
            event = JSON.parse(data)
            case event["type"]
            when "content_block_delta"
              text = event.dig("delta", "text").to_s
              block.call(text) unless text.empty?
            when "message_start"
              input_tokens = event.dig("message", "usage", "input_tokens")
            when "message_delta"
              output_tokens = event.dig("usage", "output_tokens")
            end
          rescue JSON::ParserError
            # Partial chunk — will be completed in the next read
          end
        end
      end
    end

    { input_tokens: input_tokens, output_tokens: output_tokens }
  rescue StandardError => e
    Rails.logger.error("[StreamAiResponseJob] #{e.class}: #{e.message}")
    { error: e.message }
  end
end
