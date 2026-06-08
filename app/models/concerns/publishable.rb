module Publishable
  extend ActiveSupport::Concern

  included do
    enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft
    scope :live, -> { published.where("published_at <= ?", Time.current) }
  end
end
