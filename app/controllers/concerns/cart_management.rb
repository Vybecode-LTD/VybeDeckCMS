module CartManagement
  extend ActiveSupport::Concern

  included do
    before_action :set_cart_data
    helper_method :current_cart
  end

  private

    # Populates @cart, @cart_items, and @cart_count for the layout cart drawer.
    # Skips the DB query entirely when no cart session cookie is present,
    # keeping page requests free of extra queries for first-time visitors.
    def set_cart_data
      @cart       = nil
      @cart_items = []
      @cart_count = 0

      return unless session[:cart_id]

      @cart = Cart
                .includes(cart_items: [product: { cover_image_attachment: :blob },
                                       price:   []])
                .find_by(id: session[:cart_id])
      return unless @cart

      @cart_items = @cart.cart_items.to_a
      @cart_count = @cart_items.sum(&:quantity)
    end

    # Lazily find-or-create the cart for the current visitor:
    # - Authenticated users always own their cart (user_id indexed).
    # - Anonymous users get a session-keyed cart (no user_id).
    # Writes session[:cart_id] on every call so the value stays fresh.
    def current_cart
      @current_cart ||= begin
        if Current.user
          cart = Cart.find_or_create_by!(user: Current.user)
        elsif session[:cart_id]
          cart = Cart.find_by(id: session[:cart_id]) || create_anonymous_cart
        else
          cart = create_anonymous_cart
        end
        session[:cart_id] = cart.id
        cart
      end
    end

    # Merge any pre-login anonymous session cart into the user's cart.
    # Call immediately after start_new_session_for in SessionsController.
    # `anon_cart_id` should be captured from session[:cart_id] before
    # start_new_session_for runs (which may reset the session).
    def merge_session_cart_for(user, anon_cart_id)
      return unless anon_cart_id

      user_cart = Cart.find_or_create_by!(user: user)
      anon_cart = Cart.find_by(id: anon_cart_id, user_id: nil)
      user_cart.merge_from(anon_cart) if anon_cart && anon_cart.id != user_cart.id
      session[:cart_id] = user_cart.id
    end

    def create_anonymous_cart
      cart = Cart.create!
      session[:cart_id] = cart.id
      cart
    end
end
