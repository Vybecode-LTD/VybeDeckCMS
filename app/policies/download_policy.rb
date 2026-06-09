class DownloadPolicy < ApplicationPolicy
  # Any authenticated user may visit their downloads list.
  # (require_authentication in the controller already blocks anonymous visitors;
  # this policy exists to satisfy Pundit's accounting.)
  def index? = user.present?
end
