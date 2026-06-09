class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string  :name,              null: false
      t.string  :slug,              null: false
      t.text    :description
      t.integer :status,            null: false, default: 0  # 0:draft 1:active 2:archived
      t.string  :stripe_product_id
      # Polymorphic association — wraps a Post (paywall), Album, or nil (standalone)
      t.references :productable, polymorphic: true

      t.timestamps
    end

    add_index :products, :slug, unique: true
    add_index :products, :stripe_product_id,
              unique: true, where: "stripe_product_id IS NOT NULL"
  end
end
