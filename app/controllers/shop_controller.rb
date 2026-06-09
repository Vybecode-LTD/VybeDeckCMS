class ShopController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session

  def index
    @products = policy_scope(Product)
                  .includes(:prices, cover_image_attachment: :blob)
                  .order(created_at: :desc)
  end

  def show
    @product = Product.friendly.find(params[:slug])
    authorize @product
    @price = @product.active_price
  rescue ActiveRecord::RecordNotFound
    redirect_to shop_path, alert: "Product not found."
  end
end
