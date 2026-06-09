class Post < ApplicationRecord
  include Publishable
  include Seoable
  extend FriendlyId
  friendly_id :title, use: :history

  belongs_to :author, class_name: "User"
  belongs_to :series, optional: true
  has_many :taggings, dependent: :destroy
  has_many :categories, through: :taggings
  has_rich_text :body
  has_one_attached :cover_image do |attachable|
    attachable.variant :cover, resize_to_fill: [ 1200, 675 ], preprocessed: true
  end
  has_many_attached :gallery do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 640, 480 ], preprocessed: true
  end

  validates :title, presence: true

  # ── reading time ─────────────────────────────────────────────────────────────

  # Returns estimated reading time in minutes (minimum 1).
  # Uses the standard ~200 words-per-minute rate.
  def reading_time
    word_count = body.to_plain_text.split.size
    [(word_count / 200.0).ceil, 1].max
  end
end
