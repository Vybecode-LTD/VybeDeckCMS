class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor,     null: true,  foreign_key: { to_table: :users }
      t.references :notifiable, null: false, polymorphic: true

      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, %i[recipient_id read_at],
              name: "index_notifications_on_recipient_read"
  end
end
