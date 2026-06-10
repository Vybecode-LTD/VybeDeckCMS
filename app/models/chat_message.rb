class ChatMessage < ApplicationRecord
  belongs_to :chat_channel
  belongs_to :author, class_name: "User"
  has_many :chat_reactions, dependent: :destroy
  has_one_attached :attachment

  validates :body, presence: true, unless: :attachment_attached?

  scope :visible, -> { where(deleted_at: nil) }
  scope :recent,  -> { order(created_at: :asc) }

  after_create_commit  :broadcast_append
  after_update_commit  :broadcast_replace

  def deleted?
    deleted_at.present?
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  private

  def broadcast_append
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_channel_#{chat_channel_id}",
      target: "chat-messages",
      partial: "admin/chat/message",
      locals: { message: self, current_user: nil }
    )
  end

  def broadcast_replace
    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_channel_#{chat_channel_id}",
      target: "chat-message-#{id}",
      partial: "admin/chat/message",
      locals: { message: self, current_user: nil }
    )
  end

  def attachment_attached?
    attachment.attached?
  end
end
