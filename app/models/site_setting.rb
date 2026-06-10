class SiteSetting < ApplicationRecord
  DEFAULTS = {
    "invite_only" => {
      value:       "false",
      value_type:  "boolean",
      description: "When enabled, new user registration is disabled. Existing users can still sign in."
    },
    "robots_txt_custom" => {
      value:       "",
      value_type:  "string",
      description: "Additional lines appended to the generated robots.txt (e.g. extra Disallow rules)."
    }
  }.freeze

  validates :key,        presence: true, uniqueness: true
  validates :value_type, presence: true, inclusion: { in: %w[boolean string integer] }

  # Returns the typed value for a setting key, falling back to DEFAULTS.
  def self.get(key)
    record = find_by(key: key)
    raw    = record&.value.presence || DEFAULTS.dig(key, :value) || ""
    type   = record&.value_type.presence || DEFAULTS.dig(key, :value_type) || "string"
    cast(raw, type)
  end

  # Persists a setting value (creates or updates).
  def self.set(key, value)
    record       = find_or_initialize_by(key: key)
    record.value = value.to_s
    # Only initialise type/description when creating a new row — don't clobber
    # admin edits on existing rows.  We can't use ||= because the DB column
    # default ("string") is truthy, so ||= would never replace it on a new record.
    if record.new_record?
      record.value_type  = DEFAULTS.dig(key, :value_type)  || "string"
      record.description = DEFAULTS.dig(key, :description)
    end
    record.save!
  end

  # Convenience predicate — always returns a boolean.
  def self.invite_only?
    get("invite_only")
  end

  private

  def self.cast(raw, type)
    case type
    when "boolean" then raw == "true"
    when "integer" then raw.to_i
    else raw.to_s
    end
  end
end
