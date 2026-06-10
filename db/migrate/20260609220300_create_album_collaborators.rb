class CreateAlbumCollaborators < ActiveRecord::Migration[8.1]
  def change
    create_table :album_collaborators do |t|
      t.references :album, null: false, foreign_key: true
      t.references :user,  null: false, foreign_key: true
      t.integer    :role,  null: false, default: 0
      t.timestamps
    end

    add_index :album_collaborators, %i[album_id user_id],
              unique: true, name: "index_album_collaborators_unique"
  end
end
