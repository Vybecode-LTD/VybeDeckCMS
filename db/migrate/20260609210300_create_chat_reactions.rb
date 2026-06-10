class CreateChatReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_reactions do |t|
      t.references :chat_message, null: false, foreign_key: true
      t.references :user,         null: false, foreign_key: true
      t.string  :emoji,           null: false
      t.timestamps
    end

    add_index :chat_reactions, %i[chat_message_id user_id emoji],
              unique: true, name: "index_chat_reactions_unique"
  end
end
