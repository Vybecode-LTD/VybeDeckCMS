class TrackPolicy < ApplicationPolicy
  def index?;   can_access_album?; end
  def show?;    can_access_album?; end
  def create?;  admin_accessible?; end
  def update?;  admin_accessible?; end
  def destroy?; admin_accessible?; end
  def reorder?; admin_accessible?; end

  class Scope < ApplicationPolicy::Scope
    def resolve; scope.all; end
  end

  private

  def can_access_album?
    admin_accessible? || (user && record.album.collaborators.include?(user))
  end
end
