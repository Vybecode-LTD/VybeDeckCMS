class PluginPolicy < ApplicationPolicy
  def index?;      user&.admin?; end
  def create?;     user&.admin?; end
  def activate?;   user&.admin?; end
  def deactivate?; user&.admin?; end
  def destroy?;    user&.admin?; end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.admin? ? scope.all : scope.none
    end
  end
end
