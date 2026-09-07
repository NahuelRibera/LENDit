class ListingConversationsController < ApplicationController
  before_action :require_authentication

  def create
    listing = Listing.published.find(params[:listing_id])

    if listing.user == current_user
      return redirect_to listing_path(listing), alert: "You can't message yourself about your own listing."
    end

    conversation = Conversation.between(current_user, listing.user, listing: listing)
    redirect_to conversation_path(conversation)
  end
end
