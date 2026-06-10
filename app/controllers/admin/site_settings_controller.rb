module Admin
  class SiteSettingsController < Admin::ApplicationController
    before_action :require_admin_role

    def show
      @invite_only        = SiteSetting.invite_only?
      @robots_txt_custom  = SiteSetting.get("robots_txt_custom")
    end

    def update
      SiteSetting.set("invite_only", params[:invite_only] == "1" ? "true" : "false")
      SiteSetting.set("robots_txt_custom", params[:robots_txt_custom].to_s.strip)
      redirect_to admin_settings_path, notice: "Site settings saved."
    end

    private

    def require_admin_role
      unless Current.user&.admin?
        redirect_to admin_root_path, alert: "Only admins can change site settings."
      end
    end
  end
end
