module Listings
  class StatusesController < ApplicationController
    before_action :require_authentication
    before_action :set_listing

    def update
      @listing.public_send("#{transition_action}!")
      redirect_to edit_listing_path(@listing), notice: "Listing #{@listing.status}."
    rescue Listing::InvalidTransitionError => e
      redirect_to edit_listing_path(@listing), alert: e.message
    end

    private

    def set_listing
      @listing = Listing.find(params[:listing_id])
      authorize @listing, :manage_status?
    end

    TRANSITION_ACTIONS = %w[publish pause reactivate archive].freeze

    def transition_action
      action = params[:transition].to_s
      raise Listing::InvalidTransitionError, "Unknown transition" unless TRANSITION_ACTIONS.include?(action)

      action
    end
  end
end
