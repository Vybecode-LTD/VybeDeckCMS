class CreateForumReplies < ActiveRecord::Migration[8.0]
  def change
    create_table :forum_replies do |t|
      t.references :forum_thread, null: false, foreign_key: true
      t.references :author,       null: false, foreign_key: { to_table: :users }
      t.integer :likes_count,  null: false, default: 0
      t.boolean :is_solution,  null: false, default: false

      t.timestamps
    end

    add_index :forum_replies, :is_solution
    add_index :forum_replies, %i[forum_thread_id created_at]
  end
end
