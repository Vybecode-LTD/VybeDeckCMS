class CartsController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session

  def show
    @cart       = current_cart
    reload_cart_view_data
  end

  def add_item
    @product = Product.friendly.find(params[:product_id])
    authorize @product, :show?

    @price = @product.active_price
    return redirect_to shop_product_path(@product.slug),
                       alert: "This product has no active price." unless @price

    current_cart.add_or_update_item(@product, @price)
    reload_cart_view_data

    respond_to do |format|
      format.html  { redirect_to shop_product_path(@product.slug), notice: "Added to cart." }
      format.turbo_stream
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to shop_path, alert: "Product not found."
  end

  def update_item
    @cart_item = current_cart.cart_items.find(params[:id])
    qty = params[:quantity].to_i
    qty < 1 ? @cart_item.destroy : @cart_item.update!(quantity: qty)
    reload_cart_view_data

    respond_to do |format|
      format.html  { redirect_to cart_path }
      format.turbo_stream
    end
  end

  def remove_item
    @cart_item = current_cart.cart_items.find(params[:id])
    @cart_item.destroy
    reload_cart_view_data

    respond_to do |format|
      format.html  { redirect_to cart_path }
      format.turbo_stream
    end
  end

  private

    # Re-loads the cart (and its items) into instance variables used by both the
    # full cart page and the Turbo Stream drawer update.
    def reload_cart_view_data
      @cart = Cart
                .includes(cart_items: [product: { cover_image_attachment: :blob },
                                       price:   []])
                .find(current_cart.id)
      @cart_items = @cart.cart_items.to_a
      @cart_count = @cart_items.sum(&:quantity)
    end
end
