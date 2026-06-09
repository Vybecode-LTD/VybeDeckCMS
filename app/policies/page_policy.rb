class PagePolicy < ApplicationPolicy
  # Only editor/admin may see or manage pages through the admin panel.
  # Members and subscribers have no editorial access.
  def index?   = admin_accessible?
  def show?    = record.published? || admin_accessible?
  def create?  = admin_accessible?
  def update?  = admin_accessible?
  def destroy? = user&.admin?

  class Scope < Scope
    def resolve
      return scope.all if user&.editor? || user&.admin?

      scope.live
    end
  end
end
