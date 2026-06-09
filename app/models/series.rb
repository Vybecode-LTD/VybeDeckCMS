class Series < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  has_many :posts, -> { order(:series_position) }, dependent: :nullify

  validates :title, presence: true

  # Recalculate the cached post_count after posts are added/removed.
  # Counter cache is not used because posts can be nullified, not destroyed.
  def refresh_post_count!
    update_column(:post_count, posts.published.count)
  end
end
