class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      # user is optional — guests can check out
      t.references :user,                     foreign_key: true
      t.string     :email,         null: false
      t.string     :stripe_payment_intent_id
      t.string     :stripe_customer_id
      # 0:pending 1:paid 2:failed 3:refunded
      t.integer    :status,        null: false, default: 0
      t.integer    :total_cents,   null: false, default: 0
      t.string     :currency,      null: false, default: "gbp"

      t.timestamps
    end

    add_index :orders, :stripe_payment_intent_id,
              unique: true, where: "stripe_payment_intent_id IS NOT NULL"
    add_index :orders, %i[user_id status]
    add_index :orders, :email
  end
end
