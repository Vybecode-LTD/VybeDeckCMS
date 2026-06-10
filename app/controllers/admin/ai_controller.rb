module Admin
  class AiController < Admin::ApplicationController
    def index
      authorize AiConversation, :index?
      @conversations = policy_scope(AiConversation).recent.limit(30)
      @conversation  = @conversations.first
      @messages      = @conversation&.ai_messages&.ordered || []
    end
  end
end
