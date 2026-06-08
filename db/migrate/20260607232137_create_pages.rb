class CreatePages < ActiveRecord::Migration[8.1]
  def change
    create_table :pages do |t|
      t.string :title, null: false
      t.string :slug
      t.integer :parent_id
      t.integer :position, default: 0
      t.boolean :show_in_nav, default: false
      t.integer :status, null: false, default: 0
      t.datetime :published_at
      t.string :meta_title
      t.text :meta_description

      t.timestamps
    end

    add_index :pages, :slug, unique: true
    add_index :pages, :parent_id
    add_foreign_key :pages, :pages, column: :parent_id
  end
end
