class ImpersonationLog < ApplicationRecord
  belongs_to :impersonator, class_name: "User"
  belongs_to :impersonated, class_name: "User"

  validates :started_at, presence: true

  scope :active, -> { where(ended_at: nil) }

  def active?
    ended_at.nil?
  end

  def end!
    update!(ended_at: Time.current)
  end
end
