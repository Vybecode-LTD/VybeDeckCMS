class CommunityController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session
  before_action :require_authentication, only: %i[new_thread create_thread create_reply destroy_reply like_reply report_reply]
  before_action :set_forum,  except: :index
  before_action :set_thread, only: %i[thread create_reply destroy_reply like_reply report_reply]

  # GET /community
  def index
    @forums = policy_scope(Forum).ordered
  end

  # GET /community/:slug
  def forum
    authorize @forum, :show?
    @pagy, @threads = pagy(
      policy_scope(ForumThread).where(forum: @forum).for_listing.pinned_first,
      items: 20
    )
  end

  # GET /community/:slug/new
  def new_thread
    authorize @forum, :show?
    authorize ForumThread.new(forum: @forum), :create?
    @thread = ForumThread.new
  end

  # POST /community/:slug/threads
  def create_thread
    authorize @forum, :show?
    @thread = ForumThread.new(thread_params)
    @thread.forum  = @forum
    @thread.author = Current.user
    authorize @thread, :create?
    if @thread.save
      redirect_to community_thread_path(@forum.slug, @thread), notice: "Thread posted."
    else
      render :new_thread, status: :unprocessable_entity
    end
  end

  # GET /community/:slug/:id
  def thread
    authorize @forum, :show?
    authorize @thread, :show?
    @thread.increment!(:view_count)
    @replies = @thread.forum_replies.includes(:author).order(created_at: :asc)
    @reply   = ForumReply.new(forum_thread: @thread)
  end

  # POST /community/:slug/:id/replies
  def create_reply
    authorize @forum, :show?
    @reply = ForumReply.new(reply_params)
    @reply.forum_thread = @thread
    @reply.author       = Current.user
    authorize @reply, :create?

    respond_to do |format|
      if @reply.save
        format.turbo_stream
        format.html { redirect_to community_thread_path(@forum.slug, @thread), notice: "Reply posted." }
      else
        format.html do
          @replies = @thread.forum_replies.includes(:author).order(created_at: :asc)
          render :thread, status: :unprocessable_entity
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "reply-form",
            partial: "community/reply_form",
            locals: { forum: @forum, thread: @thread, reply: @reply }
          )
        end
      end
    end
  end

  # DELETE /community/:slug/:id/replies/:reply_id
  def destroy_reply
    @reply = @thread.forum_replies.find(params[:reply_id])
    authorize @reply, :destroy?
    @reply.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("reply-#{@reply.id}") }
      format.html { redirect_to community_thread_path(@forum.slug, @thread), notice: "Reply deleted." }
    end
  end

  # POST /community/:slug/:id/replies/:reply_id/like
  def like_reply
    @reply = @thread.forum_replies.find(params[:reply_id])
    authorize @reply, :like?

    existing = Like.find_by(user: Current.user, likeable: @reply)
    if existing
      existing.destroy
    else
      Like.create!(user: Current.user, likeable: @reply)
    end
    @reply.reload

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to community_thread_path(@forum.slug, @thread) }
    end
  end

  # POST /community/:slug/:id/replies/:reply_id/report
  def report_reply
    @reply = @thread.forum_replies.find(params[:reply_id])
    authorize @reply, :report?

    @reply.report!(params[:report_reason].to_s.strip)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to community_thread_path(@forum.slug, @thread), notice: "Reply reported. Thank you." }
    end
  end

  private

  def set_forum
    @forum = Forum.friendly.find(params[:slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to community_path, alert: "Forum not found."
  end

  def set_thread
    @thread = @forum.forum_threads.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to community_forum_path(@forum.slug), alert: "Thread not found."
  end

  def thread_params
    params.require(:forum_thread).permit(:title, :body)
  end

  def reply_params
    params.require(:forum_reply).permit(:body)
  end
end
