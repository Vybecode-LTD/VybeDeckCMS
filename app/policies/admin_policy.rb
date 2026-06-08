class AdminPolicy < ApplicationPolicy
  def access?
    user&.editor? || user&.admin?
  end
end
