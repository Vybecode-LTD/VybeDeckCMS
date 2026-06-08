class MediumPolicy < ApplicationPolicy
  def index?   = user&.editor? || user&.admin?
  def show?    = user&.editor? || user&.admin?
  def create?  = user&.editor? || user&.admin?
  def update?  = user&.editor? || user&.admin?
  def destroy? = user&.admin?

  class Scope < Scope
    def resolve = scope.all
  end
end
