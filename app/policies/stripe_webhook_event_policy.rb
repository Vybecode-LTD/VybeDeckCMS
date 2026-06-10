class StripeWebhookEventPolicy < ApplicationPolicy
  def index?  = user&.admin?
  def show?   = user&.admin?
  def replay? = user&.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve = user&.admin? ? scope.all : scope.none
  end
end
