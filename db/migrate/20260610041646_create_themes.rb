class CreateThemes < ActiveRecord::Migration[8.1]
  def change
    create_table :themes do |t|
      t.string  :name,   null: false, default: "Default"
      t.boolean :active, null: false, default: false
      t.json    :tokens, null: false, default: {}
      t.timestamps
    end
    add_index :themes, :active
  end
end
