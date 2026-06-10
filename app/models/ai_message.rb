class AiMessage < ApplicationRecord
  belongs_to :ai_conversation

  enum :role, { user: 0, assistant: 1 }, default: :user

  validates :role, presence: true
  # Content may be blank while an assistant response is streaming in.
  validates :content, presence: true, length: { maximum: 32_768 }, unless: :streaming?
  validates :content, length: { maximum: 32_768 }, allow_blank: true, if: :streaming?

  scope :ordered, -> { order(:created_at) }
end
