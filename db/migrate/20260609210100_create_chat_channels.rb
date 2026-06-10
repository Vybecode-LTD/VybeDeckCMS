class CreateChatChannels < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_channels do |t|
      t.string  :name,        null: false
      t.text    :description
      t.boolean :is_private,  null: false, default: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :chat_channels, :name, unique: true
  end
end
