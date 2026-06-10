class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true

  validates :user_id, uniqueness: { scope: %i[likeable_type likeable_id],
                                    message: "has already liked this" }

  after_create_commit  :increment_likes_count
  after_destroy_commit :decrement_likes_count

  private

  def increment_likes_count
    likeable.increment!(:likes_count) if likeable.respond_to?(:likes_count)
  end

  def decrement_likes_count
    likeable.decrement!(:likes_count) if likeable.respond_to?(:likes_count)
  end
end
