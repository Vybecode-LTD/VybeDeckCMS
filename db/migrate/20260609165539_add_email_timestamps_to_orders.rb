class AddEmailTimestampsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :confirmation_email_sent_at, :datetime
    add_column :orders, :refund_receipt_sent_at, :datetime
  end
end
