class CreateAiMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_messages do |t|
      t.references :ai_conversation, null: false, foreign_key: true
      t.integer :role,          null: false, default: 0
      t.text    :content,       null: false, default: ""
      t.integer :input_tokens
      t.integer :output_tokens

      t.timestamps
    end
  end
end
