class AiConversation < ApplicationRecord
  belongs_to :user
  has_many :ai_messages, dependent: :destroy

  validates :title, length: { maximum: 200 }

  scope :recent, -> { order(created_at: :desc) }

  def self.start_for(user, first_message)
    title = first_message.to_s.truncate(80, omission: "…")
    conversation = create!(user: user, title: title)
    conversation
  end

  def total_input_tokens
    ai_messages.where(role: :assistant).sum(:input_tokens)
  end

  def total_output_tokens
    ai_messages.where(role: :assistant).sum(:output_tokens)
  end
end
