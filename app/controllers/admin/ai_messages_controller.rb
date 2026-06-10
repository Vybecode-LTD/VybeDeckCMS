module Admin
  class AiMessagesController < Admin::ApplicationController
    before_action :set_conversation

    def create
      authorize @conversation, :show?
      skip_policy_scope

      content = params[:content].to_s.strip
      return redirect_to admin_ai_conversation_path(@conversation), alert: "Message cannot be blank." if content.blank?

      @conversation.ai_messages.create!(role: :user, content: content)
      result = AiAssistantService.new(@conversation).call(content)

      if result.success?
        @conversation.ai_messages.create!(
          role:          :assistant,
          content:       result.content,
          input_tokens:  result.input_tokens,
          output_tokens: result.output_tokens
        )
      else
        @conversation.ai_messages.create!(role: :assistant, content: "_Error: #{result.error}_")
      end

      redirect_to admin_ai_conversation_path(@conversation)
    end

    private

    def set_conversation
      @conversation = AiConversation.find(params[:ai_conversation_id])
    end
  end
end
