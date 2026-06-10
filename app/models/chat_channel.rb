class ChatChannel < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  has_many :chat_messages, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { maximum: 80 }
  validates :is_private, inclusion: { in: [true, false] }

  scope :ordered, -> { order(:name) }
end
