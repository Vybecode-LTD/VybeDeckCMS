module Admin
  class AiMessagesController < Admin::ApplicationController
    before_action :set_conversation

    def create
      authorize @conversation, :show?
      skip_policy_scope

      content = params[:content].to_s.strip
      if content.blank?
        return respond_to do |format|
          format.html         { redirect_to admin_ai_conversation_path(@conversation), alert: "Message cannot be blank." }
          format.turbo_stream { head :unprocessable_entity }
        end
      end

      @user_message      = @conversation.ai_messages.create!(role: :user,      content: content)
      @assistant_message = @conversation.ai_messages.create!(role: :assistant, content: "", streaming: true)

      StreamAiResponseJob.perform_later(@assistant_message.id)

      respond_to do |format|
        format.html         { redirect_to admin_ai_conversation_path(@conversation) }
        format.turbo_stream # renders create.turbo_stream.erb
      end
    end

    private

    def set_conversation
      @conversation = AiConversation.find(params[:ai_conversation_id])
    end
  end
end
