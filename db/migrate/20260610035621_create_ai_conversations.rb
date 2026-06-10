class CreateAiConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false, default: ""

      t.timestamps
    end
  end
end
