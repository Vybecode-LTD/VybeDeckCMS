class Post < ApplicationRecord
  include Publishable
  include Seoable
  extend FriendlyId
  friendly_id :title, use: :history

  belongs_to :author, class_name: "User"
  has_many :taggings, dependent: :destroy
  has_many :categories, through: :taggings
  has_rich_text :body
  has_one_attached :cover_image
  has_many_attached :gallery

  validates :title, presence: true
end
