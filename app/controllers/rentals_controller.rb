class RentalsController < ApplicationController
  before_action :require_authentication
  before_action :set_listing, only: [:create]
  before_action :reject_own_listing, only: [:create]
  before_action :set_rental, only: [:show]

  def create
    @rental = @listing.rentals.new(rental_params.merge(borrower: current_user))
    authorize @rental

    if @rental.save
      redirect_to rental_path(@rental), notice: "Request sent. We'll notify you when the owner responds."
    else
      redirect_to listing_path(@listing), alert: @rental.errors.full_messages.to_sentence
    end
  end

  def show
    authorize @rental
  end

  private

  def set_listing
    @listing = Listing.published.find(params[:listing_id])
  end

  def set_rental
    @rental = Rental.find(params[:id])
  end

  def reject_own_listing
    return unless @listing.user_id == current_user.id

    redirect_to listing_path(@listing), alert: "You can't book your own listing."
  end

  def rental_params
    params.require(:rental).permit(:start_date, :end_date)
  end
end
