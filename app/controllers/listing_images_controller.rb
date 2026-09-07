class ListingImagesController < ApplicationController
  before_action :require_authentication
  before_action :set_listing

  def create
    files = Array(params.dig(:listing_image, :files)).reject(&:blank?)
    next_position = (@listing.listing_images.maximum(:position) || -1) + 1
    had_no_images = @listing.listing_images.none?

    files.each_with_index do |file, index|
      image = @listing.listing_images.create(file: file, position: next_position + index)
      image.update!(is_primary: true) if had_no_images && index.zero? && image.persisted?
    end

    redirect_to edit_listing_path(@listing), notice: "Photos added."
  end

  def update
    image = @listing.listing_images.find(params[:id])

    case params[:move]
    when "up" then swap_position(image, -1)
    when "down" then swap_position(image, 1)
    end

    if params[:make_primary]
      @listing.listing_images.update_all(is_primary: false)
      image.update!(is_primary: true)
    end

    redirect_to edit_listing_path(@listing)
  end

  def destroy
    image = @listing.listing_images.find(params[:id])
    was_primary = image.is_primary?
    image.destroy!

    if was_primary && (next_image = @listing.listing_images.ordered.first)
      next_image.update!(is_primary: true)
    end

    redirect_to edit_listing_path(@listing), notice: "Photo removed."
  end

  private

  def set_listing
    @listing = Listing.find(params[:listing_id])
    authorize @listing, :manage_images?
  end

  def swap_position(image, delta)
    images = @listing.listing_images.ordered.to_a
    index = images.index(image)
    neighbor = images[index + delta]
    return unless neighbor

    image.position, neighbor.position = neighbor.position, image.position
    image.save!
    neighbor.save!
  end
end
