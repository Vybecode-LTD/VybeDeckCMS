class SitemapController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session

  def index
    @posts    = Post.live.order(updated_at: :desc)
    @pages    = Page.live.where.not(slug: "home").order(updated_at: :desc)
    @albums   = Album.published.order(updated_at: :desc)
    @products = Product.active.order(updated_at: :desc)

    respond_to do |format|
      format.xml { render layout: false }
    end
  end
end
