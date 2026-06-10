class ModerationPolicy < ApplicationPolicy
  def index?
    admin_accessible?
  end
end
