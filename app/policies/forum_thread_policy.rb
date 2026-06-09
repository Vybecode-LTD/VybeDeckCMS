class ForumThreadPolicy < ApplicationPolicy
  # Admin panel index/show: editor and admin only.
  def index?
    admin_accessible?
  end

  # Public visibility is delegated to the parent forum; admin access is direct.
  def show?
    admin_accessible? || ForumPolicy.new(user, record.forum).show?
  end

  # Any authenticated user may start a thread in a forum they can see.
  def create?
    user.present?
  end

  def update?
    return false unless user
    record.author == user || admin_accessible?
  end

  def destroy?
    admin_accessible?
  end

  # Admin / editor moderation actions
  def lock?
    admin_accessible?
  end

  def pin?
    admin_accessible?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
