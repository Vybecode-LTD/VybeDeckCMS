# Custom Administrate field for has_many_attached Active Storage attachments.
# Renders a file list on show pages and a multi-file input on form pages.
class ActiveStorageMultiField < Administrate::Field::Base
  # Tell Administrate's strong-params builder to permit the attribute as an array.
  def self.permitted_attribute(attr, **_options)
    { attr => [] }
  end

  def to_s
    data.attached? ? data.map(&:filename).join(", ") : "—"
  end
end
