class CreateSeries < ActiveRecord::Migration[8.1]
  def change
    create_table :series do |t|
      t.string  :title,       null: false, default: ""
      t.string  :slug,        null: false, default: ""
      t.text    :description
      t.integer :post_count,  null: false, default: 0
      t.timestamps
    end

    add_index :series, :slug, unique: true
    add_index :series, :created_at

    add_column :posts, :series_id,       :bigint
    add_column :posts, :series_position, :integer

    add_index :posts, :series_id
    add_index :posts, [ :series_id, :series_position ]
    add_foreign_key :posts, :series
  end
end
