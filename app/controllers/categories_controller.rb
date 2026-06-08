class CategoriesController < ApplicationController
  allow_unauthenticated_access

  def show
    @category = Category.friendly.find(params[:slug])
    render plain: @category.name
  end
end
