class SettingPolicy < ApplicationPolicy
  # Any authenticated user can view and update their own settings.
  def show?   = user.present?
  def update? = user.present?
end
