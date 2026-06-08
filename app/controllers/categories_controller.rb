class CategoriesController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session

  def show
    @category = Category.friendly.find(params[:slug])
    posts_scope = policy_scope(@category.posts)
      .includes(:author, :categories, cover_image_attachment: :blob)
      .order(published_at: :desc, created_at: :desc)
    @pagy, @posts = pagy(posts_scope)
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end
end
