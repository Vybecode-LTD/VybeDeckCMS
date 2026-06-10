# Solid Cache tables.
#
# Idempotent (if_not_exists: true) so it is safe to run against a database
# that already has these tables.
#
# Uses timestamp 20240101000001 to avoid collision with the Solid Queue
# migration (20240101000000) — all databases share the same schema_migrations
# table when they use the same DATABASE_URL.
#
# Matches db/cache_schema.rb version 1.

class InstallSolidCache < ActiveRecord::Migration[8.0]
  def up
    create_table :solid_cache_entries, if_not_exists: true do |t|
      t.binary   :key,        limit: 1024,      null: false
      t.binary   :value,      limit: 536870912, null: false
      t.datetime :created_at,                   null: false
      t.integer  :key_hash,   limit: 8,         null: false
      t.integer  :byte_size,  limit: 4,         null: false

      t.index [:byte_size],            name: "index_solid_cache_entries_on_byte_size"
      t.index [:key_hash, :byte_size], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
      t.index [:key_hash],             name: "index_solid_cache_entries_on_key_hash", unique: true
    end
  end

  def down
    drop_table :solid_cache_entries, if_exists: true
  end
end
