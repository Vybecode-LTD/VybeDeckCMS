class PostPolicy < ApplicationPolicy
  def index? = true

  def show?
    record.published? ||
      user&.editor? || user&.admin? ||
      record.author_id == user&.id
  end

  def create? = user.present?

  def update?
    user&.admin? || user&.editor? || record.author_id == user&.id
  end

  def destroy? = user&.admin? || user&.editor?

  class Scope < Scope
    def resolve
      return scope.all if user&.editor? || user&.admin?

      if user.present?
        scope.where(author_id: user.id).or(scope.live)
      else
        scope.live
      end
    end
  end
end
