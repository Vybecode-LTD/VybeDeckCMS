class ChatMessagePolicy < ApplicationPolicy
  def create?;  admin_accessible?; end
  def update?;  own_message? || user&.admin?; end
  def destroy?; own_message? || user&.admin?; end

  class Scope < ApplicationPolicy::Scope
    def resolve; scope.all; end
  end

  private

  def own_message?
    record.author == user
  end
end
