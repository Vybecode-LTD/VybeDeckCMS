class Album < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: %i[slugged history]

  # draft (0) — work in progress
  # in_review (1) — sent to collaborators/client for feedback
  # mastered (2) — audio mastered, ready to publish
  # published (3) — live on the site and for sale
  enum :status, { draft: 0, in_review: 1, mastered: 2, published: 3 }, default: :draft

  has_many :tracks, -> { order(:position) }, dependent: :destroy
  has_many :album_collaborators,  dependent: :destroy
  has_many :collaborators, through: :album_collaborators, source: :user
  has_one  :product, as: :productable, dependent: :nullify
  has_one_attached :artwork

  validates :title, presence: true

  scope :ordered,    -> { order(release_date: :desc, title: :asc) }
  scope :published,  -> { where(status: :published) }

  def publish!
    errors.add(:base, "Artwork must be attached")   unless artwork.attached?
    errors.add(:base, "Release date must be set")   unless release_date.present?
    errors.add(:base, "At least one track with audio is required") unless tracks.any? { |t| t.audio.attached? }
    return false if errors.any?

    update!(status: :published)
    ensure_product!
    true
  end

  def ensure_product!
    return product if product.present?

    Product.create!(
      name:        title,
      status:      :active,
      productable: self
    )
  end

  private

  def should_generate_new_friendly_id?
    title_changed? || super
  end
end
