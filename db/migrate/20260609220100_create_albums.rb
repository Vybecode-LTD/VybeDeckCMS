class CreateAlbums < ActiveRecord::Migration[8.1]
  def change
    create_table :albums do |t|
      t.string  :title,        null: false
      t.string  :artist
      t.string  :genre
      t.string  :label
      t.string  :upc
      t.text    :description
      t.date    :release_date
      t.integer :status,       null: false, default: 0
      t.string  :slug
      # Artwork crop coordinates (applied via CSS on the public page)
      t.integer :crop_x
      t.integer :crop_y
      t.integer :crop_width
      t.integer :crop_height
      t.timestamps
    end

    add_index :albums, :slug, unique: true
  end
end
