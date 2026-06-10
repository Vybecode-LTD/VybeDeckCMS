class Track < ApplicationRecord
  belongs_to :album
  has_many   :track_versions,  dependent: :destroy
  has_many   :track_comments,  dependent: :destroy
  has_one    :product, as: :productable, dependent: :nullify
  has_one_attached :audio
  has_rich_text    :lyrics

  validates :title,    presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :preview_start_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :preview_end_seconds,   numericality: { only_integer: true, greater_than:  0 },            allow_nil: true

  before_validation :set_position, on: :create

  # When a new audio file is attached, snapshot it as a TrackVersion.
  after_save :create_version_if_audio_changed

  scope :ordered, -> { order(:position) }

  private

  def set_position
    # DB default is 0, so ||= would never fire; always auto-assign on create.
    # Caller can override by passing position: explicitly after this callback.
    self.position = (album&.tracks&.maximum(:position) || -1) + 1
  end

  def create_version_if_audio_changed
    return unless audio.attached? && saved_change_to_id? == false && audio.blob_previously_changed?
    version_number = track_versions.maximum(:version_number).to_i + 1
    track_versions.create!(
      uploaded_by:    Current.user || album.collaborators.first,
      version_number: version_number,
      notes:          "Audio updated"
    )
  end
end
