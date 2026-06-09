class MembersController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session

  def show
    @member = User.find_by!("LOWER(display_name) = LOWER(?)", params[:display_name])
    authorize @member, :show_profile?

    @posts = Post.live
                 .where(author_id: @member.id)
                 .includes(:categories, cover_image_attachment: :blob)
                 .order(published_at: :desc)
                 .limit(6)
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end
end
