module Admin
  class PluginSettingsController < Admin::ApplicationController
    before_action :set_plugin
    before_action :require_declared_settings

    def show
      authorize @plugin, :update?
      @declared_settings = @plugin.plugin_class.declared_settings
    end

    def update
      authorize @plugin, :update?
      @plugin.update_settings!(settings_params)
      redirect_to admin_plugin_settings_path(@plugin), notice: "Settings saved."
    rescue ActiveRecord::RecordInvalid => e
      @declared_settings = @plugin.plugin_class.declared_settings
      flash.now[:alert] = e.message
      render :show, status: :unprocessable_entity
    end

    private

    def set_plugin
      @plugin = Plugin.find(params[:plugin_id])
    end

    def require_declared_settings
      if @plugin.plugin_class.blank? || @plugin.plugin_class.declared_settings.empty?
        redirect_to admin_plugins_path, alert: "This plugin has no configurable settings."
      end
    end

    def settings_params
      return {} unless params[:settings].present?
      params[:settings].permit!.to_h
    end
  end
end
