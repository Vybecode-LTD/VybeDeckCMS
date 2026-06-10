module Admin
  class AlbumsController < Admin::ApplicationController
    before_action :set_album, only: %i[show edit update destroy publish]

    # GET /admin/albums — kanban grouped by status
    def index
      authorize Album, :index?
      all = policy_scope(Album).includes(:tracks, artwork_attachment: :blob).ordered
      @albums_by_status = Album.statuses.keys.index_with { |s| all.select { |a| a.status == s } }
    end

    # GET /admin/albums/:id
    def show
      authorize @album
      @tracks   = @album.tracks.ordered.includes(:audio_attachment, :track_comments)
      @collaborators = @album.album_collaborators.includes(:user)
    end

    def new
      authorize Album, :new?
      @album = Album.new
    end

    def create
      authorize Album, :create?
      @album = Album.new(album_params)
      if @album.save
        redirect_to admin_album_path(@album), notice: "Album created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @album
    end

    def update
      authorize @album
      if @album.update(album_params)
        redirect_to admin_album_path(@album), notice: "Album updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @album
      @album.destroy
      redirect_to admin_albums_path, notice: "Album deleted."
    end

    # PATCH /admin/albums/:id/publish
    def publish
      authorize @album, :publish?
      if @album.publish!
        redirect_to admin_album_path(@album), notice: "Album published and product created."
      else
        redirect_to admin_album_path(@album), alert: @album.errors.full_messages.join("; ")
      end
    end

    private

    def set_album
      @album = Album.friendly.find(params[:id])
    end

    def album_params
      params.require(:album).permit(
        :title, :artist, :genre, :label, :upc, :description,
        :release_date, :status, :artwork,
        :crop_x, :crop_y, :crop_width, :crop_height
      )
    end
  end
end
