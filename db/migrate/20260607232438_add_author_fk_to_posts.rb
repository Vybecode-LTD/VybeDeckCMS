class AddAuthorFkToPosts < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :posts, :users, column: :author_id
  end
end
