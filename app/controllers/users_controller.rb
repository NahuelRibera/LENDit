class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    authorize @user
    @listings = @user.listings.published.recent
      .includes(:category, listing_images: { file_attachment: :blob })
  end
end
