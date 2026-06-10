class AiConversationPolicy < ApplicationPolicy
  def index?;   admin_accessible?; end
  def show?;    admin_accessible? && own_or_admin?; end
  def create?;  admin_accessible?; end
  def destroy?; own_or_admin?; end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user&.admin_accessible?
      user.admin? ? scope.all : scope.where(user: user)
    end
  end

  private

  def own_or_admin?
    user&.admin? || record.user == user
  end
end
