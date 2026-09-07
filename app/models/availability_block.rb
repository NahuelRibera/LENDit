class AvailabilityBlock < ApplicationRecord
  class BookingConflictError < StandardError; end

  belongs_to :listing

  validates :start_date, :end_date, presence: true
  validates :end_date, comparison: { greater_than_or_equal_to: :start_date }, if: -> { start_date && end_date }

  scope :ordered, -> { order(:start_date) }

  # Locks the listing so this can't race a concurrent Rental#accept! for
  # the same listing (the availability_blocks table's own EXCLUDE
  # constraint protects against two overlapping blocks; this lock protects
  # the cross-table block-vs-rental race that no single-table constraint
  # can express).
  def self.create_for!(listing:, start_date:, end_date:, reason: nil)
    listing.with_lock do
      overlap = listing.rentals.blocking.where(
        "daterange(start_date, end_date, '[]') && daterange(?, ?, '[]')", start_date, end_date
      )
      raise BookingConflictError, "There's already a booking during those dates." if overlap.exists?

      listing.availability_blocks.create!(start_date: start_date, end_date: end_date, reason: reason)
    end
  rescue ActiveRecord::StatementInvalid => e
    raise BookingConflictError, "Those dates overlap another blocked period." if exclusion_violation?(e)
    raise
  end

  def self.exclusion_violation?(error)
    error.cause.is_a?(PG::ExclusionViolation) ||
      error.message.include?("conflicting key value violates exclusion constraint")
  end
end
