class Plugin < ApplicationRecord
  enum :status, { installed: 0, active: 1, disabled: 2 }, default: :installed

  validates :name,    presence: true, length: { maximum: 120 }
  validates :slug,    presence: true, uniqueness: true,
                      format: { with: /\A[a-z0-9][a-z0-9_-]*\z/,
                                message: "may only contain lowercase letters, numbers, hyphens, and underscores" }
  validates :version, presence: true

  scope :ordered,        -> { order(:name) }
  scope :active_plugins, -> { where(status: :active).order(:name) }

  def activate!
    update!(status: :active).tap do
      plugin_class&.on_activate
    end
  end

  def deactivate!
    plugin_class&.on_deactivate
    update!(status: :disabled)
  end

  def uninstall!
    plugin_class&.on_uninstall
    destroy
  end

  def plugin_class
    VybeDeck::Plugin::Registry.registered.find { |p| p.plugin_slug == slug }
  end

  def loaded?
    plugin_class.present?
  end

  # Returns the stored value for +key+, falling back to the declared default.
  def setting_value(key)
    declared = plugin_class&.declared_settings&.find { |s| s[:key] == key.to_s }
    settings.fetch(key.to_s) { declared&.fetch(:default, nil) }
  end

  # Merge +values+ hash into the settings column, casting each to its declared type.
  def update_settings!(values)
    return unless plugin_class

    new_vals = plugin_class.declared_settings.each_with_object({}) do |decl, h|
      raw = values[decl[:key]] || values[decl[:key].to_sym]
      next if raw.nil?
      h[decl[:key]] = cast_setting(raw, decl[:type])
    end

    update!(settings: settings.merge(new_vals))
  end

  private

  def cast_setting(value, type)
    case type
    when :boolean then ActiveModel::Type::Boolean.new.cast(value)
    when :integer then value.to_i
    else value.to_s
    end
  end
end
