class PasswordResetsController < ApplicationController
  def new
  end

  def create
    if user = User.find_by(email: params[:email].to_s)
      PasswordMailer.reset(user).deliver_later
    end

    # Always show the same message, whether or not the email exists,
    # so this endpoint can't be used to enumerate registered accounts.
    redirect_to new_session_path, notice: "If that email exists, we've sent password reset instructions."
  end

  def edit
    @user = find_user_by_token
    redirect_to new_password_reset_path, alert: "That reset link is invalid or has expired." unless @user
  end

  def update
    @user = find_user_by_token

    if @user.nil?
      redirect_to new_password_reset_path, alert: "That reset link is invalid or has expired."
    elsif @user.update(password_params)
      redirect_to new_session_path, notice: "Password updated. Please sign in."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def find_user_by_token
    User.find_by_token_for(:password_reset, params[:token])
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
