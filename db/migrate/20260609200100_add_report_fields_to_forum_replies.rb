class AddReportFieldsToForumReplies < ActiveRecord::Migration[8.0]
  def change
    add_column :forum_replies, :reported_at,    :datetime
    add_column :forum_replies, :report_reason,  :text
    add_index  :forum_replies, :reported_at
  end
end
