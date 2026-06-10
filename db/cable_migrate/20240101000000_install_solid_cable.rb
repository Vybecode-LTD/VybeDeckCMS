# Solid Cable tables.
#
# Idempotent (if_not_exists: true) so it is safe to run against a database
# that already has these tables.
#
# Matches db/cable_schema.rb version 1.

class InstallSolidCable < ActiveRecord::Migration[8.0]
  def up
    create_table :solid_cable_messages, if_not_exists: true do |t|
      t.binary   :channel,      limit: 1024,      null: false
      t.binary   :payload,      limit: 536870912, null: false
      t.datetime :created_at,                     null: false
      t.integer  :channel_hash, limit: 8,         null: false

      t.index [:channel],      name: "index_solid_cable_messages_on_channel"
      t.index [:channel_hash], name: "index_solid_cable_messages_on_channel_hash"
      t.index [:created_at],   name: "index_solid_cable_messages_on_created_at"
    end
  end

  def down
    drop_table :solid_cable_messages, if_exists: true
  end
end
