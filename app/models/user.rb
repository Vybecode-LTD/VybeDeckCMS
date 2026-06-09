class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts, foreign_key: :author_id, dependent: :nullify
  has_one_attached :avatar

  enum :role, { author: 0, editor: 1, admin: 2 }, default: :author

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :display_name,  with: ->(d) { d.strip }
  normalizes :website_url,   with: ->(u) { u.strip }

  validates :bio,
    length:     { maximum: 280 },
    allow_blank: true

  validates :display_name,
    length:     { maximum: 50 },
    uniqueness: { case_sensitive: false },
    allow_blank: true

  validates :website_url,
    format: {
      with:    URI::DEFAULT_PARSER.make_regexp(%w[http https]),
      message: "must be a valid http or https URL"
    },
    allow_blank: true

  validate :avatar_is_image_under_10mb

  def byline
    display_name.presence || email_address
  end

  private

  def avatar_is_image_under_10mb
    return unless avatar.attached?

    unless avatar.content_type.start_with?("image/")
      errors.add(:avatar, "must be an image file (JPEG, PNG, GIF, or WebP)")
    end

    if avatar.blob.byte_size > 10.megabytes
      errors.add(:avatar, "must be smaller than 10 MB")
    end
  end
end
