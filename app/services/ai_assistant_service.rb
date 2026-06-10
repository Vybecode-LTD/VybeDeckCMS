require "net/http"
require "uri"
require "json"

class AiAssistantService
  API_URL = "https://api.anthropic.com/v1/messages"
  MODEL   = ENV.fetch("ANTHROPIC_MODEL", "claude-haiku-4-5-20251001")

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are a helpful assistant embedded in the VybeDeck CMS admin panel.
    You help editors and administrators with:
    - Drafting pages, blog posts, and editorial content (return Action Text-compatible HTML when asked)
    - Suggesting meta titles and descriptions for SEO
    - Album and music content writing (liner notes, bios, press copy)
    - CMS workflows, publishing best practices, and content strategy
    - Bulk queries: listing draft posts, identifying gaps, summarising content

    Keep your responses focused on CMS and content tasks.
    When asked to draft content, format it cleanly with appropriate headings.
    If asked about completely unrelated topics, politely redirect to relevant CMS tasks.
  PROMPT

  Result = Struct.new(:content, :input_tokens, :output_tokens, :error, keyword_init: true) do
    def success? = error.nil?
  end

  def initialize(conversation)
    @conversation = conversation
    @api_key = ENV["ANTHROPIC_API_KEY"]
  end

  def call(user_content)
    return Result.new(error: "ANTHROPIC_API_KEY is not configured.") if @api_key.blank?

    messages = build_messages(user_content)
    response_body = post_to_api(messages)
    parse_response(response_body)
  rescue StandardError => e
    Result.new(error: "API error: #{e.message}")
  end

  private

  def build_messages(user_content)
    history = @conversation.ai_messages.ordered.map { |m| { role: m.role, content: m.content } }
    history + [ { role: "user", content: user_content } ]
  end

  def post_to_api(messages)
    uri  = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl     = true
    http.read_timeout = 60

    req = Net::HTTP::Post.new(uri)
    req["Content-Type"]      = "application/json"
    req["x-api-key"]         = @api_key
    req["anthropic-version"] = "2023-06-01"
    req.body = {
      model:      MODEL,
      max_tokens: 4096,
      system:     SYSTEM_PROMPT,
      messages:   messages
    }.to_json

    http.request(req).body
  end

  def parse_response(body)
    data = JSON.parse(body)

    if data["error"]
      return Result.new(error: data.dig("error", "message") || "Unknown API error")
    end

    content = data.dig("content", 0, "text").to_s
    Result.new(
      content:       content,
      input_tokens:  data.dig("usage", "input_tokens"),
      output_tokens: data.dig("usage", "output_tokens")
    )
  end
end
