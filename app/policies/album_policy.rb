class AlbumPolicy < ApplicationPolicy
  def index?;   admin_accessible?; end
  def show?;    admin_accessible? || collaborator?; end
  def new?;     admin_accessible?; end
  def create?;  admin_accessible?; end
  def edit?;    admin_accessible?; end
  def update?;  admin_accessible?; end
  def destroy?; user&.admin?; end
  def publish?; user&.admin?; end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      if user.admin_accessible?
        scope.all
      else
        # Collaborators can only see their own albums
        scope.joins(:album_collaborators).where(album_collaborators: { user_id: user.id })
      end
    end
  end

  private

  def collaborator?
    user && record.collaborators.include?(user)
  end
end
