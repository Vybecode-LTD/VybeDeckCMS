class AddStreamingToAiMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :ai_messages, :streaming, :boolean, null: false, default: false
  end
end
