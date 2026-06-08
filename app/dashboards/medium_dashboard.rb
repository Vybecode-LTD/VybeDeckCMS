require "administrate/base_dashboard"

# Minimal dashboard — required so Administrate includes Media in the admin nav.
# All views are custom (app/views/admin/media/).
class MediumDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {}.freeze
  COLLECTION_ATTRIBUTES = [].freeze
  SHOW_PAGE_ATTRIBUTES  = [].freeze
  FORM_ATTRIBUTES       = [].freeze

  def display_resource(medium)
    medium.title.presence || "Medium ##{medium.id}"
  end
end
