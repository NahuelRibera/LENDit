module Account
  class BorrowsController < ApplicationController
    before_action :require_authentication

    STATUS_TABS = %w[pending accepted active completed declined cancelled].freeze

    def index
      RentalLifecycleSweepJob.perform_now

      @status = params[:status].presence_in(STATUS_TABS) || "pending"
      @rentals = current_user.rentals_as_borrower.where(status: @status)
        .includes(:lender, listing: { listing_images: { file_attachment: :blob } })
        .order(created_at: :desc)
      @counts = current_user.rentals_as_borrower.group(:status).count
    end
  end
end
