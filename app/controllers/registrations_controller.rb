class RegistrationsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access
  before_action :resume_session
  before_action :redirect_if_authenticated, only: %i[new create]
  before_action :check_registration_open,   only: %i[new create]

  TOKEN_TTL = 48.hours

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.role = :member  # self-registered users are members; authors are promoted by admin

    if @user.save
      token = @user.generate_email_verification_token!
      SendEmailVerificationJob.perform_later(@user.id, token)
      redirect_to verify_email_registration_path,
        notice: "Account created! Check your inbox for a verification link."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /register/verify?token=TOKEN
  # Without a token param: shows the "check your email" holding page.
  # With a valid token: verifies the user and signs them in.
  def verify_email
    token = params[:token].to_s.strip
    return if token.blank?  # render the "check your email" page

    @user = User.find_by(email_verification_token: token)

    if @user.nil?
      flash.now[:alert] = "This verification link is invalid or has already been used."
      return render :verify_email, status: :unprocessable_entity
    end

    if token_expired?(@user)
      flash.now[:alert] = "This verification link has expired. Please request a new one below."
      @expired_email = @user.email_address
      return render :verify_email, status: :unprocessable_entity
    end

    @user.verify_email!
    start_new_session_for @user
    redirect_to settings_path,
      notice: "Email verified! Welcome to VybeDeck CMS, #{@user.byline}."
  end

  # POST /register/resend
  # Always returns the same response to prevent email enumeration.
  def resend_verification
    email = params[:email].to_s.strip.downcase
    user  = User.find_by(email_address: email)

    if user && !user.email_verified?
      token = user.generate_email_verification_token!
      SendEmailVerificationJob.perform_later(user.id, token)
    end

    redirect_to verify_email_registration_path,
      notice: "If that address is on file, we've sent a fresh verification link."
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :display_name)
  end

  def redirect_if_authenticated
    redirect_to root_path, notice: "You are already signed in." if Current.user
  end

  def check_registration_open
    if SiteSetting.invite_only?
      render plain: "Registration is currently invitation only.", status: :forbidden
    end
  end

  def token_expired?(user)
    return true unless user.email_verification_sent_at
    Time.current - user.email_verification_sent_at > TOKEN_TTL
  end
end
