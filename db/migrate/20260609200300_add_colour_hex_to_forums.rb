class AddColourHexToForums < ActiveRecord::Migration[8.1]
  def change
    add_column :forums, :colour_hex, :string
  end
end
