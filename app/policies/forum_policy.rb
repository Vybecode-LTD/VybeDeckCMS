class ForumPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    return true  if record.open?
    return false unless user
    return true  if record.members_only?
    # subscribers_only: subscriber, editor, or admin
    subscriber_or_above?
  end

  def create?
    admin_accessible?
  end

  def update?
    admin_accessible?
  end

  def destroy?
    admin_accessible?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.nil?
        scope.open
      elsif user.subscriber? || user.editor? || user.admin?
        scope.all
      else
        # authors, members: open + members_only
        scope.where(visibility: %i[open members_only])
      end
    end
  end
end
