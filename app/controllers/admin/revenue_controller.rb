module Admin
  class RevenueController < Admin::ApplicationController
    # GET /admin/revenue
    def show
      authorize :revenue, :show?

      # Monthly revenue for the last 12 complete months + current month.
      @monthly_stats = Order
        .paid
        .where(created_at: 12.months.ago.beginning_of_month..)
        .group(Arel.sql("DATE_TRUNC('month', created_at)"), :currency)
        .order(Arel.sql("DATE_TRUNC('month', created_at) DESC"), :currency)
        .select(
          Arel.sql("DATE_TRUNC('month', created_at) AS month"),
          :currency,
          Arel.sql("COUNT(*)          AS order_count"),
          Arel.sql("SUM(total_cents)  AS revenue_cents")
        )

      # All-time totals grouped by currency.
      @totals_by_currency = Order
        .paid
        .group(:currency)
        .order(:currency)
        .select(
          :currency,
          Arel.sql("COUNT(*)          AS order_count"),
          Arel.sql("SUM(total_cents)  AS revenue_cents")
        )
    end
  end
end
