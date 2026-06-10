class FaqBlock < ApplicationRecord
  belongs_to :page

  validates :question, presence: true, length: { maximum: 300 }
  validates :answer,   presence: true, length: { maximum: 2000 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  default_scope { order(:position) }

  before_validation :assign_position, on: :create

  private

  def assign_position
    self.position ||= (page&.faq_blocks&.maximum(:position).to_i + 1)
  end
end
