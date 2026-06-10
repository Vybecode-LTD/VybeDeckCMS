class TrackVersion < ApplicationRecord
  belongs_to :track
  belongs_to :uploaded_by, class_name: "User"
  has_one_attached :audio

  validates :version_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :version_number, uniqueness: { scope: :track_id }

  scope :ordered, -> { order(version_number: :desc) }
end
