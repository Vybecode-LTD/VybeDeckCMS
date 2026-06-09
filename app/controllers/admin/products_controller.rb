module Admin
  class ProductsController < Admin::ApplicationController
    # Administrate handles all CRUD.
    # Override here if custom behaviour is needed (e.g. Stripe product sync).
  end
end
