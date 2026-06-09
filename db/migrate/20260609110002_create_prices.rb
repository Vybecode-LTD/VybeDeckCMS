class CreatePrices < ActiveRecord::Migration[8.1]
  def change
    create_table :prices do |t|
      t.references :product,      null: false, foreign_key: true
      t.integer    :amount_cents, null: false
      t.string     :currency,     null: false, default: "gbp"
      t.string     :nickname
      t.string     :stripe_price_id
      t.boolean    :active,       null: false, default: true

      t.timestamps
    end

    add_index :prices, :stripe_price_id,
              unique: true, where: "stripe_price_id IS NOT NULL"
    add_index :prices, %i[product_id active]
  end
end
