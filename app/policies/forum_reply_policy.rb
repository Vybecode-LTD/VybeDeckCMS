class ForumReplyPolicy < ApplicationPolicy
  # Admin panel: editor and admin only.
  def index?
    admin_accessible?
  end

  def show?
    admin_accessible?
  end

  # Any authenticated user can reply to an unlocked thread they can see.
  def create?
    return false unless user
    !record.forum_thread.locked?
  end

  def destroy?
    return false unless user
    record.author == user || admin_accessible?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
