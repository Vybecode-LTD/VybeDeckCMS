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

      @conversation      = AiConversation.start_for(Current.user, content)
      @conversation.ai_messages.create!(role: :user,      content: content)
      assistant_message  = @conversation.ai_messages.create!(role: :assistant, content: "", streaming: true)

      StreamAiResponseJob.perform_later(assistant_message.id)

      redirect_to admin_ai_conversation_path(@conversation)
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
  end
end
