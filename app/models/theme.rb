class Theme < ApplicationRecord
  HEX_RE    = /\A#[0-9a-fA-F]{6}\z/
  RADIUS_RE = /\A\d+(\.\d+)?(px|rem|em|%|vw|vh)?\z/
  SPACE_RE  = /\A\d+(\.\d+)?(px|rem|em)?\z/

  LIGHT_DEFAULTS = {
    "light_bg"          => "#f8f7f5",
    "light_bg_elevated" => "#ffffff",
    "light_bg_sunken"   => "#f0eee9",
    "light_text"        => "#18150e",
    "light_text_muted"  => "#6b6860",
    "light_accent"      => "#e8440a"
  }.freeze

  DARK_DEFAULTS = {
    "dark_bg"          => "#0f0e0d",
    "dark_bg_elevated" => "#1a1816",
    "dark_bg_sunken"   => "#0b0a09",
    "dark_text"        => "#f0ece4",
    "dark_text_muted"  => "#8c8880",
    "dark_accent"      => "#e8440a"
  }.freeze

  FONT_DEFAULTS = {
    "font_family" => "Inter",
    "font_url"    => "https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,300;0,14..32,400;0,14..32,500;0,14..32,600;0,14..32,700;1,14..32,400&display=swap"
  }.freeze

  RADIUS_DEFAULTS = {
    "radius_sm"   => "4px",
    "radius_md"   => "8px",
    "radius_lg"   => "16px",
    "radius_full" => "9999px"
  }.freeze

  SPACING_DEFAULTS = {
    "space_unit" => "8px"
  }.freeze

  SHADOW_DEFAULTS = {
    "shadow_sm" => "0 1px 2px rgba(0,0,0,.06), 0 1px 3px rgba(0,0,0,.10)",
    "shadow_md" => "0 4px 6px rgba(0,0,0,.07), 0 2px 4px rgba(0,0,0,.06)",
    "shadow_lg" => "0 10px 15px rgba(0,0,0,.10), 0 4px 6px rgba(0,0,0,.05)"
  }.freeze

  SECTION_ACCENT_DEFAULTS = {
    "hero_accent"   => "",
    "card_accent"   => "",
    "button_accent" => ""
  }.freeze

  ALL_DEFAULTS = LIGHT_DEFAULTS
    .merge(DARK_DEFAULTS)
    .merge(FONT_DEFAULTS)
    .merge(RADIUS_DEFAULTS)
    .merge(SPACING_DEFAULTS)
    .merge(SHADOW_DEFAULTS)
    .merge(SECTION_ACCENT_DEFAULTS)
    .freeze

  AVAILABLE_FONTS = [
    { name: "Inter",            url: "https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,300;0,14..32,400;0,14..32,500;0,14..32,600;0,14..32,700;1,14..32,400&display=swap" },
    { name: "Lato",             url: "https://fonts.googleapis.com/css2?family=Lato:wght@300;400;700&display=swap" },
    { name: "Roboto",           url: "https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" },
    { name: "Montserrat",       url: "https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;600;700&display=swap" },
    { name: "Playfair Display", url: "https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,600;0,700;1,400&display=swap" },
    { name: "Merriweather",     url: "https://fonts.googleapis.com/css2?family=Merriweather:wght@300;400;700&display=swap" },
    { name: "Source Sans 3",    url: "https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@300;400;600;700&display=swap" },
    { name: "Open Sans",        url: "https://fonts.googleapis.com/css2?family=Open+Sans:wght@300;400;600;700&display=swap" },
  ].map(&:freeze).freeze

  validates :name, presence: true, length: { maximum: 100 }
  validate  :token_hex_values_valid

  def self.active_theme
    find_by(active: true)
  end

  def apply!
    Theme.where.not(id: id).update_all(active: false)
    update!(active: true)
    Rails.cache.delete("active_theme_css")
  end

  def deactivate!
    update!(active: false)
    Rails.cache.delete("active_theme_css")
  end

  def reset_to_defaults!
    update!(tokens: {})
    Rails.cache.delete("active_theme_css")
  end

  def effective_tokens
    ALL_DEFAULTS.merge(tokens.presence || {})
  end

  def to_css
    t = effective_tokens
    font_import = t["font_url"].present? ? "@import url(\"#{t["font_url"]}\");\n" : ""
    font_body   = t["font_family"].present? ? "body { font-family: '#{t["font_family"]}', sans-serif; }" : ""

    section_accent_overrides = [
      t["hero_accent"].present?   ? "--hero-accent:#{t["hero_accent"]};"     : nil,
      t["card_accent"].present?   ? "--card-accent:#{t["card_accent"]};"     : nil,
      t["button_accent"].present? ? "--button-accent:#{t["button_accent"]};" : nil,
    ].compact.join(" ")

    <<~CSS
      #{font_import}
      :root {
        --radius-sm:   #{t["radius_sm"]};
        --radius-md:   #{t["radius_md"]};
        --radius-lg:   #{t["radius_lg"]};
        --radius-full: #{t["radius_full"]};
        --space-unit:  #{t["space_unit"]};
        --shadow-sm:   #{t["shadow_sm"]};
        --shadow-md:   #{t["shadow_md"]};
        --shadow-lg:   #{t["shadow_lg"]};
        #{section_accent_overrides}
      }
      :root, [data-color-scheme="light"] {
        --bg:          #{t["light_bg"]};
        --bg-elevated: #{t["light_bg_elevated"]};
        --bg-sunken:   #{t["light_bg_sunken"]};
        --text:        #{t["light_text"]};
        --text-muted:  #{t["light_text_muted"]};
        --accent:      #{t["light_accent"]};
      }
      @media (prefers-color-scheme: dark) {
        :root:not([data-color-scheme="light"]) {
          --bg:          #{t["dark_bg"]};
          --bg-elevated: #{t["dark_bg_elevated"]};
          --bg-sunken:   #{t["dark_bg_sunken"]};
          --text:        #{t["dark_text"]};
          --text-muted:  #{t["dark_text_muted"]};
          --accent:      #{t["dark_accent"]};
        }
      }
      [data-color-scheme="dark"] {
        --bg:          #{t["dark_bg"]};
        --bg-elevated: #{t["dark_bg_elevated"]};
        --bg-sunken:   #{t["dark_bg_sunken"]};
        --text:        #{t["dark_text"]};
        --text-muted:  #{t["dark_text_muted"]};
        --accent:      #{t["dark_accent"]};
      }
      #{font_body}
    CSS
  end

  def to_json_export
    effective_tokens.to_json
  end

  private

  def token_hex_values_valid
    return if tokens.blank?
    tokens.each do |key, val|
      next if val.blank?
      case key
      when /\Afont_/
        # free-form strings — no format validation
      when /\Aradius_/
        unless val.match?(RADIUS_RE)
          errors.add(:tokens, "'#{key}' must be a CSS length value like 8px or 0.5rem (got #{val.inspect})")
        end
      when "space_unit"
        unless val.match?(SPACE_RE)
          errors.add(:tokens, "'space_unit' must be a CSS length value like 8px (got #{val.inspect})")
        end
      when /\Ashadow_/
        # CSS box-shadow — allow any string; no format restriction
      else
        unless val.match?(HEX_RE)
          errors.add(:tokens, "'#{key}' must be a 6-digit hex colour (got #{val.inspect})")
        end
      end
    end
  end
end
