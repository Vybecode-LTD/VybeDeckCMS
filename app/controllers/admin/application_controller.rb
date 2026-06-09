# All Administrate controllers inherit from this
# `Administrate::ApplicationController`, making it the ideal place to put
# authentication logic or other before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    include Authentication
    include Administrate::Punditize
    include Pagy::Backend
    helper Pagy::Frontend

    before_action :authorize_admin_access
    helper_method :current_user

    # Rescue any Pundit error raised by custom admin actions (e.g. ban, impersonate,
    # bulk_role).  Admin::ApplicationController does not inherit from the public
    # ApplicationController so it needs its own rescue_from clause.
    rescue_from Pundit::NotAuthorizedError, with: :pundit_not_authorized

    # Override this value to specify the number of elements to display at a time
    # on index pages. Defaults to 20.
    # def records_per_page
    #   params[:per_page] || 20
    # end

    private
      def current_user
        Current.user
      end

      def pundit_user
        current_user
      end

      def authorize_admin_access
        authorize :admin, :access?
      rescue Pundit::NotAuthorizedError
        flash[:alert] = "You are not authorized to access the admin."
        redirect_to root_path
      end

      def pundit_not_authorized
        flash[:alert] = "You are not authorized to perform this action."
        redirect_back_or_to root_path
      end
  end
end
