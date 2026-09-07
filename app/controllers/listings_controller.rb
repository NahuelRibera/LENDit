class ListingsController < ApplicationController
  before_action :require_authentication, except: [:index, :show]
  before_action :set_listing, only: [:show, :edit, :update]

  def index
    @search = ListingSearch.new(params, current_user: current_user)
    @pagy, @listings = pagy(@search.results)
    @categories = Category.active.ordered
  end

  def new
    @listing = current_user.listings.new
    authorize @listing
  end

  def create
    @listing = current_user.listings.new(listing_params)
    authorize @listing

    if @listing.save
      redirect_to edit_listing_path(@listing),
        notice: "Listing created as a draft. Add photos, then publish when you're ready."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @listing
    track_recently_viewed if @listing.published?
    @related_listings = Listing.published.available_to(current_user)
      .where(category_id: @listing.category_id)
      .where.not(id: @listing.id)
      .includes(:user, listing_images: { file_attachment: :blob })
      .limit(4)
    @unavailable_ranges = unavailable_ranges
  end

  def edit
    authorize @listing
  end

  def update
    authorize @listing

    if @listing.update(listing_params)
      redirect_to edit_listing_path(@listing), notice: "Listing updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_listing
    @listing = Listing.find(params[:id])
  end

  def track_recently_viewed
    if signed_in?
      record = current_user.recently_viewed_listings.find_or_initialize_by(listing: @listing)
      record.update!(viewed_at: Time.current)
    else
      session[:recently_viewed] = ([@listing.id] + Array(session[:recently_viewed])).uniq.first(10)
    end
  end

  def listing_params
    params.require(:listing).permit(:title, :description, :category_id, :condition, :price, :city)
  end

  def unavailable_ranges
    rental_ranges = @listing.rentals.blocking.pluck(:start_date, :end_date)
    block_ranges = @listing.availability_blocks.pluck(:start_date, :end_date)
    (rental_ranges + block_ranges).sort_by(&:first)
  end
end
