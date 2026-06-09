class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :bio,         :text
    add_column :users, :website_url, :string

    # Case-insensitive uniqueness on display_name when present.
    # Allows multiple users with no display_name (NULL or blank).
    add_index :users, "LOWER(display_name)",
      name:   "index_users_on_lower_display_name",
      unique: true,
      where:  "display_name IS NOT NULL AND display_name != ''"
  end
end
