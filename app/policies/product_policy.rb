class ProductPolicy < ApplicationPolicy
  # Public shop index shows active products; admin sees all.
  def index?   = true
  def show?    = record.active? || admin_accessible?
  def create?  = admin_accessible?
  def update?  = admin_accessible?
  def destroy? = user&.admin?

  # Allows downloading the product's downloadable files.
  # Admins/editors always have access; regular users need a paid order.
  def download?
    return true if admin_accessible?
    return false unless user

    user.orders.paid.joins(:line_items).where(line_items: { product: record }).exists?
  end

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
