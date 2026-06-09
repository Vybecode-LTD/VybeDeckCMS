module Admin
  class ProductsController < Admin::ApplicationController
    # Administrate handles all CRUD.
    # Override here if custom behaviour is needed (e.g. Stripe product sync).

    # Product uses FriendlyId — route params are slugs, not numeric IDs.
    def find_resource(param)
      resource_class.friendly.find(param)
    end
  end
end
