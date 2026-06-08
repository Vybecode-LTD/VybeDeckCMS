class PostsController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session

  def index
    posts_scope = policy_scope(Post)
      .includes(:author, :categories, cover_image_attachment: :blob)
      .order(published_at: :desc, created_at: :desc)
    @pagy, @posts = pagy(posts_scope)
    @categories = Category.joins(:posts).merge(Post.live).distinct.order(:name)
  end

  def show
    @post = policy_scope(Post).includes(:author, :categories, cover_image_attachment: :blob).friendly.find(params[:slug])
    authorize @post
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end
end
