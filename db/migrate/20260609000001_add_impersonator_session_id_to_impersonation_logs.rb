class AddImpersonatorSessionIdToImpersonationLogs < ActiveRecord::Migration[8.1]
  def change
    # Stores the admin's Session record ID so ImpersonationsController#destroy
    # can restore the admin without relying on Rails session state.
    add_column :impersonation_logs, :impersonator_session_id, :bigint
    add_index  :impersonation_logs, :impersonator_session_id
  end
end
