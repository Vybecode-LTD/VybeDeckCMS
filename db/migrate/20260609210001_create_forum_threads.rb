class CreateForumThreads < ActiveRecord::Migration[8.0]
  def change
    create_table :forum_threads do |t|
      t.references :forum,   null: false, foreign_key: true
      t.references :author,  null: false, foreign_key: { to_table: :users }
      t.string  :title,       null: false
      t.boolean :pinned,      null: false, default: false
      t.boolean :locked,      null: false, default: false
      t.integer :view_count,  null: false, default: 0
      t.integer :reply_count, null: false, default: 0
      t.datetime :last_reply_at

      t.timestamps
    end

    add_index :forum_threads, :pinned
    add_index :forum_threads, :locked
    add_index :forum_threads, :last_reply_at
    add_index :forum_threads, %i[forum_id pinned last_reply_at]
  end
end
