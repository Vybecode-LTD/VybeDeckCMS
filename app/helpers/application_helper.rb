module ApplicationHelper
  include Pagy::Frontend

  def active_theme_css
    Rails.cache.fetch("active_theme_css", expires_in: 1.hour) do
      Theme.active_theme&.to_css || ""
    end
  end
  def public_nav_pages
    @public_nav_pages ||= Page.live.where(show_in_nav: true).order(:position, :title)
  end

  def public_page_title(record = nil)
    title = record&.try(:meta_title).presence || record&.try(:title).presence || record&.try(:name).presence
    [ title, "VybeDeck CMS" ].compact.join(" | ")
  end

  def published_label(record)
    return "Draft" unless record.published?
    return "Scheduled" if record.published_at.present? && record.published_at.future?

    "Published"
  end

  def readable_date(value)
    return unless value

    value.to_date.to_formatted_s(:long)
  end
end
