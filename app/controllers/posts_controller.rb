class PostsController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session

  def index
    @posts = policy_scope(Post)
    render plain: @posts.map(&:title).join(", ")
  end

  def show
    @post = policy_scope(Post).friendly.find(params[:slug])
    authorize @post
    render plain: @post.title
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end
end
