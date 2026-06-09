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
    @post = policy_scope(Post)
              .includes(:author, :categories, cover_image_attachment: :blob)
              .friendly.find(params[:slug])
    authorize @post

    # Related: up to 3 live posts sharing any category, excluding the current one
    if @post.category_ids.any?
      @related_posts = Post.live
                         .joins(:taggings)
                         .where(taggings: { category_id: @post.category_ids })
                         .where.not(id: @post.id)
                         .distinct
                         .includes(:author, :categories, cover_image_attachment: :blob)
                         .order(published_at: :desc)
                         .limit(3)
    else
      @related_posts = Post.none
    end
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end
end
