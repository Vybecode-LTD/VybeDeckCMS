module Admin
  class ChatReactionsController < Admin::ApplicationController
    before_action :set_channel
    before_action :set_message

    # POST /admin/chat/:channel_id/messages/:message_id/reactions
    def create
      existing = @message.chat_reactions.find_by(user: Current.user, emoji: reaction_params[:emoji])

      if existing
        authorize existing, :destroy?
        existing.destroy
      else
        reaction = @message.chat_reactions.build(user: Current.user, emoji: reaction_params[:emoji])
        authorize reaction
        reaction.save!
      end

      head :ok
    end

    private

    def set_channel
      @channel = ChatChannel.find(params[:channel_id])
    end

    def set_message
      @message = @channel.chat_messages.find(params[:message_id])
    end

    def reaction_params
      params.require(:chat_reaction).permit(:emoji)
    end
  end
end
