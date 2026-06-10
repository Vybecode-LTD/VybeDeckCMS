class AlbumsController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session

  def index
    @albums = Album.published.ordered.includes(:artwork_attachment)
  end

  def show
    @album  = Album.published.friendly.find(params[:slug])
    @tracks = @album.tracks.ordered.includes(:audio_attachment)
    # Check if current user has purchased this album
    @purchased = current_user_has_purchased?(@album)
  end

  private

  def current_user_has_purchased?(album)
    return false unless Current.user

    product = album.product
    return false unless product

    Current.user.orders.paid
           .joins(:line_items)
           .where(line_items: { product: product })
           .exists?
  end
end
