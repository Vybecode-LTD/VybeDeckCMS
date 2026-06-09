class AddEmailVerificationToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :email_verified_at,          :datetime
    add_column :users, :email_verification_token,    :string
    add_column :users, :email_verification_sent_at,  :datetime

    # Unique index so two concurrent verifications can't race on the same token.
    # Partial: only index non-NULL tokens (rows after token is cleared go unreferenced).
    add_index :users, :email_verification_token,
      unique: true,
      where:  "email_verification_token IS NOT NULL",
      name:   "index_users_on_email_verification_token"

    # All users that existed before email verification was introduced are
    # considered pre-verified — they were admin-created or migrated in.
    User.update_all(email_verified_at: Time.current)
  end

  def down
    remove_index :users, name: "index_users_on_email_verification_token"
    remove_column :users, :email_verification_sent_at
    remove_column :users, :email_verification_token
    remove_column :users, :email_verified_at
  end
end
