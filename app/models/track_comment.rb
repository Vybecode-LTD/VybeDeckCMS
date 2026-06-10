class TrackComment < ApplicationRecord
  belongs_to :track
  belongs_to :author, class_name: "User"

  validates :body, presence: true, length: { maximum: 2000 }

  scope :recent, -> { order(created_at: :asc) }
end
