module Rentals
  class CancellationsController < ApplicationController
    before_action :require_authentication
    before_action :set_rental

    def create
      if @rental.pending?
        @rental.withdraw!(by: current_user)
        redirect_to rental_path(@rental), notice: "Request withdrawn."
      elsif @rental.accepted?
        role = current_user == @rental.borrower ? "borrower" : "lender"
        @rental.cancel!(by: current_user, reason: params[:reason].presence || "Cancelled by the #{role}.")
        redirect_to rental_path(@rental), notice: "Booking cancelled."
      else
        redirect_to rental_path(@rental), alert: "This booking can no longer be cancelled."
      end
    rescue Rental::InvalidTransitionError => e
      redirect_to rental_path(@rental), alert: e.message
    end

    private

    def set_rental
      @rental = Rental.find(params[:rental_id])
      authorize @rental, :cancel?
    end
  end
end
