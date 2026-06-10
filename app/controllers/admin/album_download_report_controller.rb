module Admin
  class AlbumDownloadReportController < Admin::ApplicationController
    def show
      authorize :album_download_report, :show?
      # Group paid line items whose product is an Album or Track
      paid_order_ids = Order.paid.pluck(:id)
      @line_items = LineItem
        .where(order_id: paid_order_ids)
        .joins(:product)
        .includes(:product, order: :user)
        .where(products: { productable_type: %w[Album Track] })
        .order("orders.created_at DESC")

      skip_policy_scope  # report builds query directly; scope not applicable
    end
  end
end
