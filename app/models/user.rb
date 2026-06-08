class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts, foreign_key: :author_id, dependent: :nullify

  enum :role, { author: 0, editor: 1, admin: 2 }, default: :author

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def byline
    display_name.presence || email_address
  end
end
