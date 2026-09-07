module Account
  class ListingsController < ApplicationController
    before_action :require_authentication

    def index
      @listings = current_user.listings
        .includes(:category, listing_images: { file_attachment: :blob })
        .order(created_at: :desc)
    end
  end
end
