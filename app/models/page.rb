class Page < ApplicationRecord
  include Publishable
  include Seoable
  extend FriendlyId
  friendly_id :title, use: :slugged

  belongs_to :parent, class_name: "Page", optional: true
  has_many :children, class_name: "Page",
    foreign_key: :parent_id, dependent: :nullify

  has_rich_text :body
  has_one_attached :hero_image

  validates :title, presence: true
end
