module Admin
  class StripeWebhookEventsController < Admin::ApplicationController
    before_action :set_event, only: %i[show replay]

    def index
      authorize StripeWebhookEvent, :index?
      @events = policy_scope(StripeWebhookEvent).recent.limit(100)
    end

    def show
      authorize @event
    end

    def replay
      authorize @event, :replay?
      unless @event.replayable?
        return redirect_to admin_stripe_webhook_event_path(@event),
               alert: "Event type '#{@event.event_type}' cannot be replayed."
      end
      ReplayStripeWebhookJob.perform_later(@event.id)
      redirect_to admin_stripe_webhook_event_path(@event),
                  notice: "Replay enqueued. The event will be reprocessed shortly."
    end

    private

    def set_event
      @event = StripeWebhookEvent.find(params[:id])
    end
  end
end
