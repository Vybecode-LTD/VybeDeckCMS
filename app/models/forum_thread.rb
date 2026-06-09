class ForumThread < ApplicationRecord
  belongs_to :forum
  belongs_to :author, class_name: "User"
  has_many   :forum_replies, dependent: :destroy
  has_rich_text :body

  validates :title, presence: true, length: { maximum: 255 }
  validates :body,  presence: true

  scope :pinned_first, -> { order(pinned: :desc, last_reply_at: :desc, created_at: :desc) }
  scope :for_listing,  -> { includes(:author) }
end
