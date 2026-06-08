class Post < ApplicationRecord
  include Publishable
  include Seoable
  extend FriendlyId
  friendly_id :title, use: :history

  belongs_to :author, class_name: "User"
  has_many :taggings, dependent: :destroy
  has_many :categories, through: :taggings
  has_rich_text :body
  has_one_attached :cover_image do |attachable|
    attachable.variant :cover, resize_to_fill: [ 1200, 675 ], preprocessed: true
  end
  has_many_attached :gallery do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 640, 480 ], preprocessed: true
  end

  validates :title, presence: true
end
