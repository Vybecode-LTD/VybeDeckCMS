class FaqBlockPolicy < ApplicationPolicy
  def create?  = admin_accessible?
  def update?  = admin_accessible?
  def destroy? = admin_accessible?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
