module Account
  class LendsController < ApplicationController
    before_action :require_authentication

    STATUS_TABS = %w[pending accepted active completed declined cancelled].freeze

    def index
      RentalLifecycleSweepJob.perform_now

      @status = params[:status].presence_in(STATUS_TABS) || "pending"
      @rentals = current_user.rentals_as_lender.where(status: @status)
        .includes(:borrower, listing: { listing_images: { file_attachment: :blob } })
        .order(created_at: :desc)
      @counts = current_user.rentals_as_lender.group(:status).count
    end
  end
end
