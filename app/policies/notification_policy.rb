class NotificationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(recipient: user)
    end
  end
end
