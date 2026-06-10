class ThemePolicy < ApplicationPolicy
  def show?   = user&.admin?
  def update? = user&.admin?
  def export? = user&.admin?
  def import? = user&.admin?
  def reset?  = user&.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
