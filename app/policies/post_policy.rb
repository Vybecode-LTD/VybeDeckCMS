class PostPolicy < ApplicationPolicy
  def index? = true

  def show?
    # Editor/admin see everything regardless of status or gating.
    return true if admin_accessible?

    # Authors can always view their own posts (drafts, subscriber-gated, etc.).
    return true if record.author_id == user&.id

    # Non-published posts are invisible to everyone else.
    return false unless record.published?

    # Published subscriber-gated posts: subscriber/editor/admin only.
    return subscriber_or_above? if record.requires_subscriber?

    # Ordinary published post: visible to all (including guests).
    true
  end

  # Only content creators (author/editor/admin) may create posts.
  # Members and subscribers are public-facing roles, not editorial ones.
  def create? = content_creator?

  def update?
    admin_accessible? || record.author_id == user&.id
  end

  def destroy? = admin_accessible?

  class Scope < Scope
    def resolve
      # Editor/admin see every post in every state.
      return scope.all if user&.editor? || user&.admin?

      # Subscriber: see all live posts including subscriber-gated ones.
      # Everyone else: exclude subscriber-gated posts from public listing.
      accessible_live = user&.subscriber? ? scope.live : scope.live.where(requires_subscriber: false)

      # Authors also see their own posts (any status, any gating).
      return scope.where(author_id: user.id).or(accessible_live) if user&.author?

      accessible_live
    end
  end
end
