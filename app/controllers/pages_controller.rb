class PagesController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session

  def show
    @page = policy_scope(Page).friendly.find(params[:id])
    authorize @page
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end
end
