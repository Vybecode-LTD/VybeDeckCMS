class CreateCartItems < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_items do |t|
      t.references :cart,    null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :price,   null: false, foreign_key: true
      t.integer    :quantity, null: false, default: 1
      t.timestamps
    end

    # One cart item per product per cart — quantity tracks count, not rows.
    add_index :cart_items, %i[cart_id product_id], unique: true
  end
end
