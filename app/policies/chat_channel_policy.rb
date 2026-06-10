class ChatChannelPolicy < ApplicationPolicy
  def index?;   admin_accessible?; end
  def show?;    admin_accessible? && (user.admin? || !record.is_private); end
  def create?;  user&.admin?; end
  def update?;  user&.admin?; end
  def destroy?; user&.admin?; end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user&.admin_accessible?

      user.admin? ? scope.all : scope.where(is_private: false)
    end
  end
end
