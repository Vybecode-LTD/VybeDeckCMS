class SendEmailVerificationJob < ApplicationJob
  queue_as :default

  # user_id and token are passed separately so we can still deliver even if
  # the user row has been updated between enqueue and execution.
  def perform(user_id, token)
    user = User.find_by(id: user_id)

    # Skip if the user was deleted or already verified since job was enqueued.
    return unless user && !user.email_verified?

    UserMailer.email_verification(user, token).deliver_now
  end
end
