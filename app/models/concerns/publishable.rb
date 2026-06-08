module Publishable
  extend ActiveSupport::Concern

  included do
    enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft
    scope :live, -> { published.where("published_at <= ?", Time.current) }

    before_save :set_published_at_on_publish
  end

  private

  def set_published_at_on_publish
    if status_changed? && published? && published_at.nil?
      self.published_at = Time.current
    end
  end
end
