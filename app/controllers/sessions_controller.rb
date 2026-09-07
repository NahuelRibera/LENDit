class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s)

    if user&.authenticate(params[:password])
      sign_in(user)
      redirect_to root_path, notice: "Welcome back, #{user.first_name}."
    else
      flash.now[:alert] = "Incorrect email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    redirect_to root_path, notice: "You've been signed out."
  end
end
