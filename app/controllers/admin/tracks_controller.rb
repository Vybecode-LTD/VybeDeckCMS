module Admin
  class TracksController < Admin::ApplicationController
    before_action :set_album
    before_action :set_track, only: %i[show edit update destroy]

    def show
      authorize @track
      @versions = @track.track_versions.ordered
      @comments = @track.track_comments.recent.includes(:author)
    end

    def new
      authorize Track.new(album: @album), :create?
      @track = @album.tracks.build
    end

    def create
      @track = @album.tracks.build(track_params)
      authorize @track
      if @track.save
        redirect_to admin_album_track_path(@album, @track), notice: "Track added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @track
    end

    def update
      authorize @track
      if @track.update(track_params)
        redirect_to admin_album_track_path(@album, @track), notice: "Track updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @track
      @track.destroy
      redirect_to admin_album_path(@album), notice: "Track removed."
    end

    # PATCH /admin/albums/:album_id/tracks/reorder — receives positions array
    def reorder
      authorize Track.new(album: @album), :reorder?
      positions = params[:positions].to_a  # array of track IDs in new order
      positions.each_with_index do |track_id, index|
        @album.tracks.where(id: track_id).update_all(position: index)
      end
      head :ok
    end

    private

    def set_album
      @album = Album.friendly.find(params[:album_id])
    end

    def set_track
      @track = @album.tracks.find(params[:id])
    end

    def track_params
      params.require(:track).permit(
        :title, :position, :duration_seconds, :isrc,
        :preview_start_seconds, :preview_end_seconds,
        :credits, :audio, :lyrics
      )
    end
  end
end
