class HomeController < ApplicationController
  def index
    @recent_listings = Listing.published.available_to(current_user).recent
      .includes(:user, :category, listing_images: { file_attachment: :blob })
      .limit(10)

    @recently_viewed_listings = recently_viewed_listings
  end

  private

  def recently_viewed_listings
    ids = if signed_in?
      current_user.recently_viewed_listings.order(viewed_at: :desc).limit(8).pluck(:listing_id)
    else
      Array(session[:recently_viewed]).first(8)
    end

    return Listing.none if ids.blank?

    listings = Listing.published.available_to(current_user).where(id: ids)
      .includes(:user, :category, listing_images: { file_attachment: :blob })
      .index_by(&:id)

    ids.filter_map { |id| listings[id] }
  end
end
