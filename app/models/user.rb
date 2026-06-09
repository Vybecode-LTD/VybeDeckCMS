class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts, foreign_key: :author_id, dependent: :nullify
  has_one_attached :avatar

  # author (0): can write posts; assigned by editor/admin
  # editor (1): full content management; can access admin panel
  # admin  (2): full access including settings and user management
  # member (3): default for self-registered users; can browse, buy, comment
  # subscriber (4): paid member; same as member + subscriber-gated content
  enum :role, { author: 0, editor: 1, admin: 2, member: 3, subscriber: 4 }, default: :author

  # True if the user can write or manage content (used in Pundit helpers).
  def content_creator?
    author? || editor? || admin?
  end

  # True if the user may access the admin panel.
  def admin_accessible?
    editor? || admin?
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
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

  def email_verified?
    email_verified_at.present?
  end

  # Generates a fresh verification token, persists it, and returns the raw token.
  def generate_email_verification_token!
    token = SecureRandom.urlsafe_base64(32)
    update!(
      email_verification_token:   token,
      email_verification_sent_at: Time.current
    )
    token
  end

  # Marks the email as verified and invalidates the token.
  def verify_email!
    update!(
      email_verified_at:          Time.current,
      email_verification_token:   nil,
      email_verification_sent_at: nil
    )
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
