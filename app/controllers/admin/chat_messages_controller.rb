module Admin
  class ChatMessagesController < Admin::ApplicationController
    before_action :set_channel
    before_action :set_message, only: %i[update destroy]

    # POST /admin/chat/:channel_id/messages
    def create
      @message = @channel.chat_messages.build(message_params)
      @message.author = Current.user
      authorize @message

      if @message.save
        # broadcast happens via after_create_commit on the model
        head :ok
      else
        render json: { error: @message.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end

    # PATCH /admin/chat/:channel_id/messages/:id
    def update
      authorize @message
      if @message.update(message_params.merge(edited_at: Time.current))
        # broadcast happens via after_update_commit on the model
        head :ok
      else
        render json: { error: @message.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end

    # DELETE /admin/chat/:channel_id/messages/:id
    def destroy
      authorize @message
      @message.soft_delete!
      head :ok
    end

    private

    def set_channel
      @channel = ChatChannel.find(params[:channel_id])
    end

    def set_message
      @message = @channel.chat_messages.find(params[:id])
    end

    def message_params
      params.require(:chat_message).permit(:body, :attachment)
    end
  end
end
