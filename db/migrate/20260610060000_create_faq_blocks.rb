class CreateFaqBlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :faq_blocks do |t|
      t.references :page, null: false, foreign_key: true
      t.string  :question, null: false
      t.text    :answer,   null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :faq_blocks, [:page_id, :position]
  end
end
