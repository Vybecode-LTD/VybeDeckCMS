module Admin
  # Ends an active impersonation session and restores the original admin account.
  # Inherits from ::ApplicationController (NOT Admin::ApplicationController) so it is
  # reachable by the impersonated user, who may not be an editor/admin.
  # IMPORTANT: use ::ApplicationController (root-namespace prefix) — without it, Ruby
  # resolves the unqualified name to Admin::ApplicationController within this module,
  # which would gate all requests through authorize_admin_access.
  class ImpersonationsController < ::ApplicationController
    def destroy
      # Find the most recent active impersonation for the currently signed-in user.
      log = ImpersonationLog
              .where(impersonated: Current.user, ended_at: nil)
              .order(started_at: :desc)
              .first

      return redirect_to root_path unless log.present?

      impersonator_session_id = log.impersonator_session_id

      # Close the audit entry.
      log.end!

      # Destroy the impersonated session.
      Current.session&.destroy

      # Restore the original admin session.
      if impersonator_session_id && (original = Session.find_by(id: impersonator_session_id))
        cookies.signed.permanent[:session_id] = {
          value:     original.id,
          httponly:  true,
          same_site: :lax
        }
        redirect_to admin_users_path,
          notice: "Impersonation ended. Welcome back, #{original.user.byline}."
      else
        cookies.delete(:session_id)
        redirect_to new_session_path,
          alert: "Your admin session expired during impersonation. Please sign in again."
      end
    end
  end
end
