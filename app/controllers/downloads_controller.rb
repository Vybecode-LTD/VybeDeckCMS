class DownloadsController < ApplicationController
  # Unauthenticated visitors are redirected to sign-in by
  # ApplicationController's require_authentication before_action.

  rescue_from Pundit::NotAuthorizedError do
    redirect_to account_downloads_path,
                alert: "You don't have access to that download. Please check your purchases."
  end

  # GET /account/downloads
  # Lists all products with downloadable files the current user has purchased.
  def index
    authorize :download, :index?

    @purchased_products = Product
      .joins(line_items: :order)
      .where(orders: { user: Current.user, status: :paid })
      .distinct
      .includes(:download_files_attachments)
      .select { |p| p.download_files.attached? }
  end

  # GET /account/downloads/:id  (id is the blob signed_id)
  # Verifies purchase authorisation and redirects to a signed download URL.
  def show
    blob = ActiveStorage::Blob.find_signed!(params[:id])

    attachment = ActiveStorage::Attachment.find_by!(
      blob_id:     blob.id,
      record_type: "Product",
      name:        "download_files"
    )

    @product = attachment.record
    authorize @product, :download?

    # rails_blob_path generates a path through ActiveStorage::BlobsController,
    # which in turn redirects to the service-layer signed URL (disk or S3).
    redirect_to rails_blob_path(blob, disposition: "attachment")

  rescue ActiveRecord::RecordNotFound
    redirect_to account_downloads_path, alert: "File not found."
  rescue ActiveSupport::MessageVerifier::InvalidSignature,
         ActiveSupport::MessageEncryptor::InvalidMessage
    redirect_to account_downloads_path, alert: "Invalid or expired download link."
  end
end
