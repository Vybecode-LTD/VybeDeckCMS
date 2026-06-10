module Admin
  class ModerationController < Admin::ApplicationController
    # GET /admin/moderation
    def index
      authorize :moderation, :index?
      # Use policy_scope to satisfy Administrate::Punditize's verify_policy_scoped;
      # ForumReplyPolicy::Scope returns scope.all for admin_accessible users.
      @pagy, @reported_replies = pagy(
        policy_scope(ForumReply).where.not(reported_at: nil)
                                .includes(:author, forum_thread: :forum)
                                .order(reported_at: :asc),
        items: 25
      )
    end

    # PATCH /admin/moderation/:id/approve
    def approve
      @reply = ForumReply.find(params[:id])
      authorize @reply, :approve?
      @reply.clear_report!
      redirect_to admin_moderation_index_path, notice: "Report cleared — reply stays visible."
    end

    # DELETE /admin/moderation/:id/remove
    def remove
      @reply = ForumReply.find(params[:id])
      authorize @reply, :approve?
      @reply.destroy
      redirect_to admin_moderation_index_path, notice: "Reply removed."
    end
  end
end
