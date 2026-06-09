module Admin
  # Extends Administrate's default CRUD (inherited via Admin::ApplicationController)
  # with ban/unban, impersonation (Login-as), and bulk role assignment.
  class UsersController < Admin::ApplicationController
    # Override index for a search-friendly query and Pagy pagination.
    def index
      @search = params[:search].to_s.strip
      scope = User.order(created_at: :desc)
      if @search.present?
        scope = scope.where(
          "email_address ILIKE :q OR display_name ILIKE :q",
          q: "%#{@search}%"
        )
      end
      @pagy, @users = pagy(scope)
    end

    # Override show to load audit data alongside the user record.
    def show
      @user = User.find(params[:id])
      @recent_posts = @user.posts.order(created_at: :desc).limit(10)
      @impersonation_logs = ImpersonationLog
        .where(impersonated: @user)
        .order(started_at: :desc)
        .limit(10)
    end

    # PATCH /admin/users/:id/ban
    def ban
      @user = User.find(params[:id])
      authorize @user, :ban?
      @user.ban!
      redirect_to admin_user_path(@user), notice: "#{@user.byline} has been banned."
    end

    # PATCH /admin/users/:id/unban
    def unban
      @user = User.find(params[:id])
      authorize @user, :unban?
      @user.unban!
      redirect_to admin_user_path(@user), notice: "#{@user.byline} has been unbanned."
    end

    # POST /admin/users/:id/impersonate
    def impersonate
      @target = User.find(params[:id])
      authorize @target, :impersonate?

      # Record the impersonation, storing the admin's Session ID directly on the
      # log row so ImpersonationsController#destroy can restore it from the DB
      # rather than relying on the Rails session (which may be opaque after the
      # session_id cookie swap below).
      log = ImpersonationLog.create!(
        impersonator:            current_user,
        impersonated:            @target,
        started_at:              Time.current,
        impersonator_session_id: Current.session.id
      )

      # Create a real session for the target user (overwrites the session_id cookie).
      start_new_session_for @target
      redirect_to main_app.root_path,
        notice: "You are now impersonating #{@target.byline}. " \
                "Use the banner at the top to exit."
    end

    # PATCH /admin/users/bulk_role
    def bulk_role
      authorize User, :bulk_role?

      role = params[:role].to_s
      ids  = Array(params[:user_ids]).map(&:to_i).reject(&:zero?)

      return redirect_to admin_users_path, alert: "No users selected."   if ids.empty?
      return redirect_to admin_users_path, alert: "Invalid role."         unless User.roles.key?(role)

      count = User.where(id: ids).update_all(role: User.roles[role])
      redirect_to admin_users_path, notice: "Updated #{count} user(s) to the #{role} role."
    end
  end
end
