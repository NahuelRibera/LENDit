module Rentals
  class AcceptancesController < ApplicationController
    before_action :require_authentication
    before_action :set_rental

    def create
      @rental.accept!
      redirect_to rental_path(@rental), notice: "Booking accepted."
    rescue Rental::InvalidTransitionError, Rental::BookingConflictError => e
      redirect_to rental_path(@rental), alert: e.message
    end

    private

    def set_rental
      @rental = Rental.find(params[:rental_id])
      authorize @rental, :accept?
    end
  end
end
