class ProductPolicy < ApplicationPolicy
  # Public shop index shows active products; admin sees all.
  def index?   = true
  def show?    = record.active? || admin_accessible?
  def create?  = admin_accessible?
  def update?  = admin_accessible?
  def destroy? = user&.admin?

  class Scope < Scope
    def resolve
      return scope.all if admin_accessible?
      scope.for_sale
    end

    private

    def admin_accessible?
      user&.editor? || user&.admin?
    end
  end
end
