class PagePolicy < ApplicationPolicy
  def index? = user.present?

  def show? = record.published? || user&.editor? || user&.admin?

  def create? = user&.editor? || user&.admin?

  def update? = user&.editor? || user&.admin?

  def destroy? = user&.admin?

  class Scope < Scope
    def resolve
      return scope.all if user&.editor? || user&.admin?

      scope.live
    end
  end
end
