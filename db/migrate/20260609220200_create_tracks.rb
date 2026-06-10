class CreateTracks < ActiveRecord::Migration[8.1]
  def change
    create_table :tracks do |t|
      t.references :album,                null: false, foreign_key: true
      t.string  :title,                   null: false
      t.integer :position,                null: false, default: 0
      t.integer :duration_seconds
      t.string  :isrc
      t.integer :preview_start_seconds,   null: false, default: 0
      t.integer :preview_end_seconds,     null: false, default: 30
      t.text    :credits
      t.timestamps
    end

    add_index :tracks, %i[album_id position], name: "index_tracks_on_album_and_position"
  end
end
