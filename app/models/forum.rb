class Forum < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: %i[slugged finders history]

  has_many :forum_threads, dependent: :destroy

  enum :visibility, { open: 0, members_only: 1, subscribers_only: 2 }

  validates :name,        presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :position,    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :visibility,  presence: true

  scope :ordered, -> { order(position: :asc, created_at: :asc) }

  def latest_thread
    forum_threads.order(last_reply_at: :desc, created_at: :desc).first
  end

  def should_generate_new_friendly_id?
    name_changed? || super
  end
end
