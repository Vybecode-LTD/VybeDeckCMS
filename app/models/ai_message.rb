class AiMessage < ApplicationRecord
  belongs_to :ai_conversation

  enum :role, { user: 0, assistant: 1 }, default: :user

  validates :role,    presence: true
  validates :content, presence: true, length: { maximum: 32_768 }

  scope :ordered, -> { order(:created_at) }
end
