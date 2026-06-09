class OrderPolicy < ApplicationPolicy
  # Admins/editors manage orders; a user can view their own orders.
  def index?  = admin_accessible?
  def show?   = admin_accessible? || record.user_id == user&.id
  def create? = true   # any visitor can place an order
  def update? = admin_accessible?
  def destroy? = user&.admin?

  class Scope < Scope
    def resolve
      return scope.all                  if admin_accessible?
      return scope.where(user: user)    if user.present?
      scope.none
    end

    private

    def admin_accessible?
      user&.editor? || user&.admin?
    end
  end
end
