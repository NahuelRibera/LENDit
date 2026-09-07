module Account
  class ProfilesController < ApplicationController
    before_action :require_authentication

    def edit
      @user = current_user
    end

    def update
      @user = current_user

      if @user.update(profile_params)
        redirect_to edit_account_profile_path, notice: "Profile updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def profile_params
      params.require(:user).permit(:first_name, :last_name, :bio, :city, :avatar, :password, :password_confirmation)
    end
  end
end
