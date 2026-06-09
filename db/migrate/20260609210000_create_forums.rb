class CreateForums < ActiveRecord::Migration[8.0]
  def change
    create_table :forums do |t|
      t.string  :name,        null: false
      t.string  :slug,        null: false
      t.text    :description
      t.integer :visibility,  null: false, default: 0
      t.integer :position,    null: false, default: 0
      t.string  :icon

      t.timestamps
    end

    add_index :forums, :slug,       unique: true
    add_index :forums, :visibility
    add_index :forums, :position
  end
end
