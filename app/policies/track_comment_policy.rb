class TrackCommentPolicy < ApplicationPolicy
  def create?;  admin_accessible? || collaborator?; end
  def destroy?; own_comment? || user&.admin?; end

  class Scope < ApplicationPolicy::Scope
    def resolve; scope.all; end
  end

  private

  def own_comment?;  record.author == user; end
  def collaborator?; user && record.track.album.collaborators.include?(user); end
end
