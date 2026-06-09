class UserPolicy < ApplicationPolicy
  # Public member profiles are always visible.
  def show_profile? = true
end
