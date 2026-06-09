class CategoryPolicy < ApplicationPolicy
  def index?   = admin_accessible?
  def show?    = admin_accessible?
  def create?  = admin_accessible?
  def update?  = admin_accessible?
  def destroy? = user&.admin?

  class Scope < Scope
    def resolve = scope.all
  end
end
