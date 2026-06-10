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
end
