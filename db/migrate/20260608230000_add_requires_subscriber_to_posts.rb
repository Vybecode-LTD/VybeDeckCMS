class AddRequiresSubscriberToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :requires_subscriber, :boolean, null: false, default: false
    add_index  :posts, :requires_subscriber
  end
end
