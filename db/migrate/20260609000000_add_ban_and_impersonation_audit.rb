class AddBanAndImpersonationAudit < ActiveRecord::Migration[8.1]
  def change
    # Ban flag: nullable timestamp — nil means active, non-nil means banned.
    add_column :users, :banned_at, :datetime

    # Audit trail for admin impersonation (Login-as).
    create_table :impersonation_logs do |t|
      t.references :impersonator, null: false, foreign_key: { to_table: :users }
      t.references :impersonated, null: false, foreign_key: { to_table: :users }
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.timestamps
    end
  end
end
