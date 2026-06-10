class CreateChatMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_messages do |t|
      t.references :chat_channel, null: false, foreign_key: true
      t.references :author,       null: false, foreign_key: { to_table: :users }
      t.text    :body
      t.datetime :edited_at
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :chat_messages, %i[chat_channel_id created_at],
              name: "index_chat_messages_on_channel_and_time"
  end
end
