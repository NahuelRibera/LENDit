class Rental < ApplicationRecord
  class InvalidTransitionError < StandardError; end
  class BookingConflictError < StandardError; end

  belongs_to :listing
  belongs_to :borrower, class_name: "User"
  belongs_to :lender, class_name: "User"
  belongs_to :cancelled_by, class_name: "User", optional: true

  enum :status, { pending: "pending", accepted: "accepted", active: "active",
                  completed: "completed", declined: "declined", cancelled: "cancelled" }, validate: true

  validates :end_date, comparison: { greater_than_or_equal_to: :start_date }, if: -> { start_date && end_date }
  validate :borrower_is_not_lender
  validate :listing_is_published, on: :create
  validate :start_date_not_in_the_past, on: :create
  validate :no_overlapping_accepted_or_active_rental, on: :create

  before_validation :assign_lender, on: :create
  before_validation :snapshot_pricing, on: :create
  before_validation :assign_requested_at, on: :create

  after_create_commit :notify_lender_of_request

  scope :blocking, -> { where(status: %w[accepted active]) }

  # Both start_date and end_date are occupied days: Sep 10-12 is 3 rental
  # days, never "nights" (see architecture notes).
  def rental_days
    (end_date - start_date).to_i + 1
  end

  def accept!
    raise InvalidTransitionError, "Only a pending request can be accepted" unless pending?

    listing.with_lock do
      if overlapping_availability_blocks.exists?
        raise BookingConflictError, "The owner has blocked these dates."
      end

      update!(status: "accepted", accepted_at: Time.current)
      decline_other_overlapping_pending_requests!
    end
    Notifications::Notifier.notify(recipient: borrower, actor: lender, notifiable: self, verb: "rental_accepted")
  rescue ActiveRecord::StatementInvalid => e
    raise BookingConflictError, "These dates were just booked by someone else." if exclusion_violation?(e)
    raise
  end

  def decline!
    raise InvalidTransitionError, "Only a pending request can be declined" unless pending?

    update!(status: "declined", declined_at: Time.current)
    Notifications::Notifier.notify(recipient: borrower, actor: lender, notifiable: self, verb: "rental_declined")
  end

  def withdraw!(by:)
    raise InvalidTransitionError, "Only a pending request can be withdrawn" unless pending?
    raise InvalidTransitionError, "Only the borrower can withdraw a request" unless by == borrower

    update!(status: "cancelled", cancelled_at: Time.current, cancelled_by: by,
      cancellation_reason: "Withdrawn by borrower before it was accepted.")
    Notifications::Notifier.notify(recipient: lender, actor: borrower, notifiable: self, verb: "rental_cancelled")
  end

  def cancel!(by:, reason:)
    raise InvalidTransitionError, "Only an accepted booking can be cancelled" unless accepted?
    raise InvalidTransitionError, "This booking already started and can't be cancelled" unless start_date.future?
    raise InvalidTransitionError, "Only a participant can cancel this booking" unless [borrower, lender].include?(by)

    update!(status: "cancelled", cancelled_at: Time.current, cancelled_by: by, cancellation_reason: reason)
    other_party = (by == borrower) ? lender : borrower
    Notifications::Notifier.notify(recipient: other_party, actor: by, notifiable: self, verb: "rental_cancelled")
  end

  def activate!
    raise InvalidTransitionError, "Only an accepted booking can become active" unless accepted?

    update!(status: "active", started_at: Time.current)
    Notifications::Notifier.notify(recipient: borrower, notifiable: self, verb: "rental_active")
    Notifications::Notifier.notify(recipient: lender, notifiable: self, verb: "rental_active")
  end

  def complete!
    raise InvalidTransitionError, "Only an active booking can be completed" unless active?

    update!(status: "completed", completed_at: Time.current)
    Notifications::Notifier.notify(recipient: borrower, notifiable: self, verb: "rental_completed")
    Notifications::Notifier.notify(recipient: lender, notifiable: self, verb: "rental_completed")
  end

  private

  def notify_lender_of_request
    Notifications::Notifier.notify(recipient: lender, actor: borrower, notifiable: self, verb: "rental_requested")
  end

  def assign_lender
    self.lender_id ||= listing&.user_id
  end

  def assign_requested_at
    self.requested_at ||= Time.current
  end

  def snapshot_pricing
    return unless listing

    self.daily_price_cents ||= listing.price_cents
    self.total_price_cents = daily_price_cents * rental_days if daily_price_cents && start_date && end_date
  end

  def borrower_is_not_lender
    errors.add(:borrower_id, "can't rent your own listing") if borrower_id.present? && borrower_id == lender_id
  end

  def listing_is_published
    errors.add(:listing, "must be published to request a booking") if listing && !listing.published?
  end

  def start_date_not_in_the_past
    errors.add(:start_date, "can't be in the past") if start_date && start_date < Date.current
  end

  def no_overlapping_accepted_or_active_rental
    return unless listing_id && start_date && end_date

    conflicting = listing.rentals.blocking.where(overlap_sql, start_date, end_date)
    conflicting = conflicting.where.not(id: id) if persisted?
    errors.add(:base, "These dates are no longer available") if conflicting.exists?
  end

  def overlapping_availability_blocks
    listing.availability_blocks.where(overlap_sql, start_date, end_date)
  end

  def overlap_sql
    "daterange(start_date, end_date, '[]') && daterange(?, ?, '[]')"
  end

  def decline_other_overlapping_pending_requests!
    listing.rentals.pending.where.not(id: id).where(overlap_sql, start_date, end_date).find_each do |rental|
      rental.update!(status: "declined", declined_at: Time.current,
        cancellation_reason: "Another request was accepted for overlapping dates.")
      Notifications::Notifier.notify(recipient: rental.borrower, notifiable: rental, verb: "rental_declined")
    end
  end

  def exclusion_violation?(error)
    error.cause.is_a?(PG::ExclusionViolation) ||
      error.message.include?("conflicting key value violates exclusion constraint")
  end
end
