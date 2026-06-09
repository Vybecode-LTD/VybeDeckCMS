class CreateLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :line_items do |t|
      t.references :order,   null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :price,   null: false, foreign_key: true
      t.integer    :quantity,          null: false, default: 1
      t.integer    :unit_amount_cents, null: false

      t.timestamps
    end
  end
end
