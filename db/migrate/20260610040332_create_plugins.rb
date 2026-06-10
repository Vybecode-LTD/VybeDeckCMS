class CreatePlugins < ActiveRecord::Migration[8.1]
  def change
    create_table :plugins do |t|
      t.string  :name,        null: false
      t.string  :slug,        null: false
      t.string  :version,     null: false, default: "0.0.1"
      t.string  :author
      t.text    :description
      t.integer :status,      null: false, default: 0
      t.json    :manifest,    default: {}
      t.json    :settings,    default: {}
      t.timestamps
    end

    add_index :plugins, :slug, unique: true
  end
end
