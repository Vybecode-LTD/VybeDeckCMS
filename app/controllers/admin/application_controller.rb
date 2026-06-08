# All Administrate controllers inherit from this
# `Administrate::ApplicationController`, making it the ideal place to put
# authentication logic or other before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    include Authentication
    include Pundit::Authorization

    before_action :authorize_admin_access
    helper_method :current_user

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
  end
end
