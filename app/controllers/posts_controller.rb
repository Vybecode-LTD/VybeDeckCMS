class PostsController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session

  def index
    @posts = policy_scope(Post)
      .includes(:author, :categories, cover_image_attachment: :blob)
      .order(published_at: :desc, created_at: :desc)
    @categories = Category.joins(:posts).merge(Post.live).distinct.order(:name)
  end

  def show
    @post = policy_scope(Post).includes(:author, :categories, cover_image_attachment: :blob).friendly.find(params[:slug])
    authorize @post
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end
end
