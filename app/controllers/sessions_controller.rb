class SessionsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      unless user.email_verified?
        return redirect_to verify_email_registration_path,
          alert: "Please verify your email address before signing in."
      end
      # Banned users receive the same generic error as wrong credentials to
      # prevent leaking account status to potential attackers.
      if user.banned?
        return redirect_to new_session_path, alert: "Try another email address or password."
      end
      anon_cart_id = session[:cart_id]  # capture before session may change
      start_new_session_for user
      merge_session_cart_for(user, anon_cart_id)
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
