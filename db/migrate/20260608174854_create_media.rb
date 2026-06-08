class CreateMedia < ActiveRecord::Migration[8.1]
  def change
    create_table :media do |t|
      t.string  :title,            null: false, default: ""
      t.string  :alt_text
      t.text    :caption
      t.integer :file_type,        null: false, default: 0
      t.bigint  :byte_size
      t.float   :duration_seconds
      t.references :owner,         polymorphic: true, null: true, index: true
      t.references :uploaded_by,   null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :media, :file_type
    add_index :media, :created_at
  end
end
