module Rentals
  class DeclinesController < ApplicationController
    before_action :require_authentication
    before_action :set_rental

    def create
      @rental.decline!
      redirect_to rental_path(@rental), notice: "Request declined."
    rescue Rental::InvalidTransitionError => e
      redirect_to rental_path(@rental), alert: e.message
    end

    private

    def set_rental
      @rental = Rental.find(params[:rental_id])
      authorize @rental, :decline?
    end
  end
end
