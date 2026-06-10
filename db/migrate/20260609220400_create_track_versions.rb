class CreateTrackVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :track_versions do |t|
      t.references :track,       null: false, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.integer    :version_number, null: false, default: 1
      t.text       :notes
      t.timestamps
    end
  end
end
