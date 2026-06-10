class Admin::ThemeController < Admin::ApplicationController
  def show
    @theme = current_theme
    authorize @theme
  end

  def update
    @theme = current_theme
    authorize @theme
    @theme.assign_attributes(theme_params)
    if @theme.save
      @theme.apply!
      redirect_to admin_theme_path, notice: "Theme saved and applied."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def export
    @theme = current_theme
    authorize @theme, :export?
    send_data @theme.to_json_export,
              type:        :json,
              disposition: :attachment,
              filename:    "theme-#{Date.today}.json"
  end

  def import
    @theme = current_theme
    authorize @theme, :import?
    file = params[:theme_json]
    unless file.respond_to?(:read)
      redirect_to admin_theme_path, alert: "Please choose a JSON file to import." and return
    end
    raw    = file.read
    parsed = JSON.parse(raw)
    valid_keys = Theme::ALL_DEFAULTS.keys
    filtered   = parsed.slice(*valid_keys)
    @theme.update!(tokens: filtered)
    @theme.apply!
    redirect_to admin_theme_path, notice: "Theme imported successfully."
  rescue JSON::ParserError
    redirect_to admin_theme_path, alert: "Invalid JSON — could not parse the file."
  rescue => e
    redirect_to admin_theme_path, alert: "Import failed: #{e.message}"
  end

  def reset
    @theme = current_theme
    authorize @theme, :reset?
    @theme.reset_to_defaults!
    redirect_to admin_theme_path, notice: "Theme reset to defaults."
  end

  private

  def current_theme
    Theme.active_theme || Theme.find_or_create_by!(name: "Default") { |t| t.active = true }
  end

  def theme_params
    permitted = params.require(:theme).permit(:name)
    raw_tokens = params.dig(:theme, :tokens)
    tokens = raw_tokens&.permit(
      :light_bg, :light_bg_elevated, :light_bg_sunken,
      :light_text, :light_text_muted, :light_accent,
      :dark_bg, :dark_bg_elevated, :dark_bg_sunken,
      :dark_text, :dark_text_muted, :dark_accent,
      :font_family, :font_url
    )&.to_h
    permitted.merge(tokens: tokens || {})
  end
end
