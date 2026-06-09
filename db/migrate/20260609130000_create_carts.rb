class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts do |t|
      # index: false — we add a partial unique index below to allow multiple
      # anonymous (user_id NULL) carts while enforcing one cart per user.
      t.references :user, foreign_key: true, index: false
      t.timestamps
    end

    add_index :carts, :user_id, unique: true, where: "user_id IS NOT NULL"
  end
end
