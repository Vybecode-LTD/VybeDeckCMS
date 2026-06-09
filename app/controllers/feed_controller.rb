class FeedController < ApplicationController
  allow_unauthenticated_access

  def show
    @posts = Post.live
                 .includes(:author, :categories)
                 .order(published_at: :desc)
                 .limit(20)
    respond_to do |format|
      format.xml { render layout: false }
    end
  end
end
