class ChatReaction < ApplicationRecord
  belongs_to :chat_message
  belongs_to :user

  validates :emoji, presence: true, length: { maximum: 10 }
  validates :user_id, uniqueness: { scope: %i[chat_message_id emoji] }

  after_create_commit  :broadcast_reactions
  after_destroy_commit :broadcast_reactions

  private

  def broadcast_reactions
    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_channel_#{chat_message.chat_channel_id}",
      target: "message-reactions-#{chat_message_id}",
      partial: "admin/chat/reactions",
      locals: { message: chat_message.reload, current_user: nil }
    )
  end
end
