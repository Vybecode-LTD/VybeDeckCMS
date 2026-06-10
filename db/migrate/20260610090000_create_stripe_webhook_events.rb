class CreateStripeWebhookEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :stripe_webhook_events do |t|
      t.string  :stripe_event_id, null: false
      t.string  :event_type,      null: false
      t.jsonb   :payload,         null: false, default: {}
      t.datetime :processed_at
      t.text    :error_message
      t.integer :replay_count, null: false, default: 0
      t.timestamps
    end

    add_index :stripe_webhook_events, :stripe_event_id, unique: true
    add_index :stripe_webhook_events, :event_type
    add_index :stripe_webhook_events, :created_at
  end
end
