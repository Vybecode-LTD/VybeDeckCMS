class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  include Pagy::Backend

  rescue_from Pundit::NotAuthorizedError, with: :pundit_not_authorized

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private
    def pundit_user
      Current.user
    end

    def pundit_not_authorized
      flash[:alert] = "You are not authorized to perform this action."
      redirect_back_or_to root_path
    end

    # True when an admin has used Login-as and is browsing as another user.
    # Resolved via a DB lookup (memoised per-request) so it survives the
    # session_id cookie swap that start_new_session_for performs.
    def impersonating?
      return false unless Current.user.present?
      @impersonating ||= ImpersonationLog.exists?(
        impersonated: Current.user, ended_at: nil
      )
    end
    helper_method :impersonating?
end
