class Medium < ApplicationRecord
  belongs_to :owner, polymorphic: true, optional: true
  belongs_to :uploaded_by, class_name: "User"
  has_one_attached :file

  enum :file_type, { image: 0, audio: 1, video: 2, document: 3 }, default: :image

  ACCEPTED_TYPES = {
    image:    %w[image/jpeg image/png image/gif image/webp image/avif image/svg+xml],
    audio:    %w[audio/mpeg audio/wav audio/flac audio/aac audio/x-flac audio/x-wav],
    video:    %w[video/mp4 video/x-msvideo video/quicktime video/webm],
    document: %w[application/pdf
                 application/vnd.openxmlformats-officedocument.wordprocessingml.document
                 text/plain
                 application/zip]
  }.freeze

  ALL_TYPES = ACCEPTED_TYPES.values.flatten.freeze
  MAX_BYTES = 200.megabytes

  validates :title, presence: true
  validate :file_must_be_attached
  validate :file_acceptable, if: -> { file.attached? }

  after_create_commit :cache_byte_size

  def self.infer_type(content_type)
    ACCEPTED_TYPES.each { |k, v| return k.to_s if v.include?(content_type) }
    nil
  end

  private

  def file_must_be_attached
    errors.add(:file, "must be attached") unless file.attached?
  end

  def file_acceptable
    errors.add(:file, "is too large (max 200 MB)") if file.byte_size > MAX_BYTES
    unless ALL_TYPES.include?(file.content_type)
      errors.add(:file, "type #{file.content_type} is not supported")
    end
  end

  def cache_byte_size
    update_column(:byte_size, file.byte_size) if file.attached? && byte_size.nil?
  end
end
