# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end

  private

  # editor or admin — may access the admin panel and manage all content.
  def admin_accessible?
    user&.editor? || user&.admin?
  end

  # author, editor, or admin — may create and edit posts/pages.
  def content_creator?
    user&.author? || user&.editor? || user&.admin?
  end

  # subscriber, editor, or admin — may view subscriber-gated content.
  def subscriber_or_above?
    user&.subscriber? || user&.editor? || user&.admin?
  end
end
