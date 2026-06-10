module Admin
  class ChatController < Admin::ApplicationController
    before_action :set_channel, only: :show

    def index
      authorize ChatChannel, :index?
      @channels = policy_scope(ChatChannel).ordered
      @channel  = @channels.first
      @messages = @channel ? visible_messages(@channel) : []
      render :show
    end

    def show
      authorize @channel
      @channels = policy_scope(ChatChannel).ordered
      @messages = visible_messages(@channel)
    end

    # POST /admin/chat/channels
    def create_channel
      authorize ChatChannel, :create?
      @channel = ChatChannel.new(channel_params.merge(created_by: Current.user))
      if @channel.save
        redirect_to admin_chat_channel_path(@channel), notice: "Channel ##{@channel.name} created."
      else
        @channels = policy_scope(ChatChannel).ordered
        @messages = []
        flash.now[:alert] = @channel.errors.full_messages.join(", ")
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_channel
      @channel = ChatChannel.find(params[:id])
    end

    def visible_messages(channel)
      channel.chat_messages
             .visible
             .recent
             .includes(:author, :chat_reactions)
             .last(50)
    end

    def channel_params
      params.require(:chat_channel).permit(:name, :description, :is_private)
    end
  end
end
