class SettingsController < ApplicationController
  def show
    authorize :setting, :show?
    @user = Current.user
  end

  # PATCH /settings — update profile fields (display_name, bio, website_url, avatar, email)
  def update
    authorize :setting, :update?
    @user = Current.user

    if @user.update(profile_params)
      redirect_to settings_path, notice: "Settings saved."
    else
      render :show, status: :unprocessable_entity
    end
  end

  # PATCH /settings/update_password
  def update_password
    authorize :setting, :update?
    @user = Current.user

    unless @user.authenticate(params[:current_password].to_s)
      return redirect_to settings_path, alert: "Current password is incorrect."
    end

    if params[:password].to_s != params[:password_confirmation].to_s
      return redirect_to settings_path, alert: "New passwords do not match."
    end

    if params[:password].to_s.length < 12
      return redirect_to settings_path, alert: "New password must be at least 12 characters."
    end

    @user.update!(password: params[:password])
    redirect_to settings_path, notice: "Password updated."
  end

  private

  def profile_params
    permitted = params.require(:user).permit(
      :display_name, :bio, :website_url, :avatar, :email_address
    )
    # Drop avatar key entirely when no file was chosen — avoids accidentally
    # detaching an existing avatar via a nil assignment.
    permitted.delete(:avatar) if permitted[:avatar].blank?
    permitted
  end
end
