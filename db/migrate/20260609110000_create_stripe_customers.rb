class CreateStripeCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :stripe_customers do |t|
      # index: { unique: true } ensures one StripeCustomer record per User
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :stripe_customer_id, null: false

      t.timestamps
    end

    add_index :stripe_customers, :stripe_customer_id, unique: true
  end
end
