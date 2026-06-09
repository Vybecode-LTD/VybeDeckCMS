class SeriesController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session

  def show
    @series = Series.friendly.find(params[:slug])
    @posts  = policy_scope(Post)
                .where(series: @series)
                .includes(:author, :categories, cover_image_attachment: :blob)
                .order(:series_position, :published_at)
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end
end
