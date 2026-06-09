class UserPolicy < ApplicationPolicy
  # Admin panel user list and detail — editors and admins can view.
  def index? = admin_accessible?
  def show?  = admin_accessible?

  # Public member profiles are always visible.
  def show_profile? = true

  # Only admins may ban, unban, impersonate, or bulk-change roles.
  def ban?        = user&.admin?
  def unban?      = user&.admin?
  def bulk_role?  = user&.admin?

  # Admins may impersonate any non-admin user (prevents recursive impersonation).
  def impersonate? = user&.admin? && !record.admin?

  class Scope < Scope
    def resolve = scope.all
  end
end
