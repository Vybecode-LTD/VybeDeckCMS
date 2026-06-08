class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :taggings, dependent: :destroy
  has_many :posts, through: :taggings

  validates :name, presence: true
end
