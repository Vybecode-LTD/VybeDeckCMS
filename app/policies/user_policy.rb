class UserPolicy < ApplicationPolicy
  # Public member profiles are always visible.
  def show_profile? = true

  # Only admins may ban, unban, impersonate, or bulk-change roles.
  def ban?        = user&.admin?
  def unban?      = user&.admin?
  def bulk_role?  = user&.admin?

  # Admins may impersonate any non-admin user (prevents recursive admin impersonation).
  def impersonate? = user&.admin? && !record.admin?
end
