module Admin
  class TrackCommentsController < Admin::ApplicationController
    before_action :set_album
    before_action :set_track

    # POST /admin/albums/:album_id/tracks/:track_id/comments
    def create
      @comment = @track.track_comments.build(comment_params.merge(author: Current.user))
      authorize @comment
      if @comment.save
        redirect_to admin_album_track_path(@album, @track), notice: "Comment added."
      else
        redirect_to admin_album_track_path(@album, @track), alert: @comment.errors.full_messages.join(", ")
      end
    end

    # DELETE /admin/albums/:album_id/tracks/:track_id/comments/:id
    def destroy
      @comment = @track.track_comments.find(params[:id])
      authorize @comment
      @comment.destroy
      redirect_to admin_album_track_path(@album, @track), notice: "Comment deleted."
    end

    private

    def set_album
      @album = Album.friendly.find(params[:album_id])
    end

    def set_track
      @track = @album.tracks.find(params[:track_id])
    end

    def comment_params
      params.require(:track_comment).permit(:body)
    end
  end
end
