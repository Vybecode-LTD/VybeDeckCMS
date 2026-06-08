class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :slug
      t.integer :author_id
      t.text :excerpt
      t.integer :status, null: false, default: 0
      t.datetime :published_at
      t.string :meta_title
      t.text :meta_description

      t.timestamps
    end

    add_index :posts, :slug, unique: true
    add_index :posts, :author_id
  end
end
