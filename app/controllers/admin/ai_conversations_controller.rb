module Admin
  class AiConversationsController < Admin::ApplicationController
    before_action :set_conversation, only: %i[show destroy]

    def show
      authorize @conversation
      @conversations = policy_scope(AiConversation).recent.limit(30)
      @messages      = @conversation.ai_messages.ordered
    end

    def create
      authorize AiConversation, :create?
      content = params[:content].to_s.strip
      return redirect_to admin_ai_path, alert: "Message cannot be blank." if content.blank?

      @conversation = AiConversation.start_for(Current.user, content)
      result = call_ai(@conversation, content)

      if result.success?
        @conversation.ai_messages.create!(role: :user,      content: content)
        @conversation.ai_messages.create!(
          role:          :assistant,
          content:       result.content,
          input_tokens:  result.input_tokens,
          output_tokens: result.output_tokens
        )
        redirect_to admin_ai_conversation_path(@conversation)
      else
        @conversation.destroy
        redirect_to admin_ai_path, alert: result.error
      end
    end

    def destroy
      authorize @conversation
      @conversation.destroy
      redirect_to admin_ai_path, notice: "Conversation deleted."
    end

    private

    def set_conversation
      @conversation = AiConversation.find(params[:id])
    end

    def call_ai(conversation, content)
      AiAssistantService.new(conversation).call(content)
    end
  end
end
