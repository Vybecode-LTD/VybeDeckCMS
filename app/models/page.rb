class Page < ApplicationRecord
  include Publishable
  include Seoable
  extend FriendlyId
  friendly_id :title, use: :slugged

  belongs_to :parent, class_name: "Page", optional: true
  has_many :children, class_name: "Page",
    foreign_key: :parent_id, dependent: :nullify
  has_many :faq_blocks, dependent: :destroy

  has_rich_text :body
  has_one_attached :hero_image do |attachable|
    attachable.variant :hero, resize_to_fill: [ 1600, 900 ], preprocessed: true
  end

  validates :title, presence: true
end
