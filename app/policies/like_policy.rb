class LikePolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    return false unless user
    record.user == user || admin_accessible?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
