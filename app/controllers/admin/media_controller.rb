module Admin
  class MediaController < Admin::ApplicationController
    before_action :set_medium, only: %i[show edit update destroy]

    def index
      scope = Medium.includes(:uploaded_by, file_attachment: :blob)
      scope = scope.public_send(params[:filter]) if valid_filter?
      scope = scope.where("title ILIKE ?", "%#{params[:search]}%") if params[:search].present?
      @pagy, @media = pagy(scope.order(created_at: :desc), items: 24)
    end

    def show; end

    def new
      @medium = Medium.new
    end

    def create
      @medium = Medium.new(medium_params)
      @medium.uploaded_by = current_user
      auto_set_file_type
      auto_set_title
      if @medium.save
        redirect_to admin_media_path, notice: "#{@medium.title} uploaded."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @medium.update(update_params)
        redirect_to admin_medium_path(@medium), notice: "Updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @medium.destroy!
      redirect_to admin_media_path, notice: "Deleted."
    end

    def bulk_destroy
      ids = (params[:medium_ids] || []).map(&:to_i)
      Medium.where(id: ids).find_each(&:destroy)
      redirect_to admin_media_path, notice: "#{ids.size} file(s) deleted."
    end

    private

    def set_medium
      @medium = Medium.find(params[:id])
    end

    def medium_params
      params.require(:medium).permit(:title, :alt_text, :caption, :file)
    end

    def update_params
      params.require(:medium).permit(:title, :alt_text, :caption)
    end

    def valid_filter?
      params[:filter].present? && Medium.file_types.key?(params[:filter])
    end

    def auto_set_file_type
      return unless @medium.file.attached?
      inferred = Medium.infer_type(@medium.file.content_type)
      @medium.file_type = inferred if inferred
    end

    def auto_set_title
      return if @medium.title.present? || !@medium.file.attached?
      @medium.title = @medium.file.filename.base.humanize
    end
  end
end
