class RevenuePolicy < ApplicationPolicy
  # Revenue reports are accessible to editors and admins.
  def show? = admin_accessible?
end
