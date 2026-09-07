require "test_helper"

class RentalTest < ActiveSupport::TestCase
  def build_rental(listing:, borrower:, start_date:, end_date:)
    listing.rentals.new(borrower: borrower, start_date: start_date, end_date: end_date)
  end

  test "valid rentals from fixtures" do
    assert rentals(:pending_request).valid?
    assert rentals(:accepted_booking).valid?
  end

  test "rental_days is inclusive of both start and end date" do
    rental = build_rental(listing: listings(:vive), borrower: users(:elena),
      start_date: Date.new(2027, 9, 10), end_date: Date.new(2027, 9, 12))
    assert_equal 3, rental.rental_days
  end

  test "requested_at is always set server-side on create, regardless of what's assigned beforehand" do
    rental = build_rental(listing: listings(:vive), borrower: users(:elena),
      start_date: 3.days.from_now.to_date, end_date: 5.days.from_now.to_date)
    assert_nil rental.requested_at

    rental.save!
    assert_not_nil rental.requested_at
    assert_in_delta Time.current, rental.requested_at, 5.seconds
  end

  test "snapshots the daily and total price at creation time" do
    rental = build_rental(listing: listings(:vive), borrower: users(:elena),
      start_date: 3.days.from_now.to_date, end_date: 5.days.from_now.to_date)
    rental.save!

    assert_equal listings(:vive).price_cents, rental.daily_price_cents
    assert_equal rental.daily_price_cents * 3, rental.total_price_cents

    listings(:vive).update!(price: 999)
    assert_equal 2200, rental.reload.daily_price_cents, "existing rental price must not change with the listing"
  end

  test "cannot rent your own listing" do
    rental = build_rental(listing: listings(:vive), borrower: users(:marti),
      start_date: 3.days.from_now.to_date, end_date: 5.days.from_now.to_date)
    assert_not rental.valid?
    assert_includes rental.errors[:borrower_id], "can't rent your own listing"
  end

  test "cannot book an unpublished listing" do
    rental = build_rental(listing: listings(:draft_drone), borrower: users(:elena),
      start_date: 3.days.from_now.to_date, end_date: 5.days.from_now.to_date)
    assert_not rental.valid?
    assert_includes rental.errors[:listing], "must be published to request a booking"
  end

  test "cannot book dates in the past" do
    rental = build_rental(listing: listings(:vive), borrower: users(:elena),
      start_date: 2.days.ago.to_date, end_date: 1.day.from_now.to_date)
    assert_not rental.valid?
    assert_includes rental.errors[:start_date], "can't be in the past"
  end

  test "rejects a new request overlapping an already-accepted booking" do
    rental = build_rental(listing: listings(:canon), borrower: users(:nahuel),
      start_date: rentals(:accepted_booking).start_date, end_date: rentals(:accepted_booking).end_date)
    assert_not rental.valid?
    assert_includes rental.errors[:base], "These dates are no longer available"
  end

  test "allows multiple overlapping PENDING requests for the same listing" do
    listing = listings(:canon)
    first = build_rental(listing: listing, borrower: users(:nahuel),
      start_date: 20.days.from_now.to_date, end_date: 22.days.from_now.to_date)
    first.save!

    second = build_rental(listing: listing, borrower: users(:marti),
      start_date: 21.days.from_now.to_date, end_date: 23.days.from_now.to_date)
    assert second.valid?
  end

  test "the PostgreSQL EXCLUDE constraint is the final guard against overlapping accepted/active rentals" do
    listing = listings(:vive)
    existing = rentals(:pending_request)

    conflicting = listing.rentals.create!(borrower: users(:nahuel), lender: users(:marti),
      start_date: existing.start_date + 5, end_date: existing.end_date + 5,
      status: "pending", daily_price_cents: 2200, total_price_cents: 4400, requested_at: Time.current)

    # Force both into "accepted" for overlapping dates, bypassing app-level
    # validation entirely (update_columns skips validations/callbacks) —
    # this proves the database constraint itself blocks it, not just Ruby.
    existing.update_columns(status: "accepted", start_date: Date.current + 5, end_date: Date.current + 8)

    assert_raises(ActiveRecord::StatementInvalid) do
      conflicting.update_columns(status: "accepted", start_date: Date.current + 6, end_date: Date.current + 7)
    end
  end

  test "accept! transitions a pending rental and auto-declines overlapping pending requests" do
    listing = listings(:canon)
    winner = build_rental(listing: listing, borrower: users(:nahuel),
      start_date: 30.days.from_now.to_date, end_date: 32.days.from_now.to_date)
    winner.save!
    loser = build_rental(listing: listing, borrower: users(:marti),
      start_date: 31.days.from_now.to_date, end_date: 33.days.from_now.to_date)
    loser.save!

    winner.accept!

    assert winner.accepted?
    assert loser.reload.declined?
  end

  test "accept! raises a booking conflict instead of a raw database error when dates were just taken" do
    listing = listings(:canon)
    rental = build_rental(listing: listing, borrower: users(:nahuel),
      start_date: rentals(:accepted_booking).start_date, end_date: rentals(:accepted_booking).end_date)
    # simulate a request that slipped in before the other was accepted —
    # save!(validate: false) skips the before_validation callbacks too, so
    # populate what they would normally have set
    rental.lender = listing.user
    rental.daily_price_cents = listing.price_cents
    rental.total_price_cents = listing.price_cents * rental.rental_days
    rental.requested_at = Time.current
    rental.save!(validate: false)

    assert_raises(Rental::BookingConflictError) { rental.accept! }
  end

  test "accept! is blocked by an owner-created availability block" do
    listing = listings(:tent)
    block_start = 15.days.from_now.to_date
    AvailabilityBlock.create_for!(listing: listing, start_date: block_start, end_date: block_start + 2)

    rental = build_rental(listing: listing, borrower: users(:marti), start_date: block_start, end_date: block_start + 1)
    rental.lender = listing.user
    rental.daily_price_cents = listing.price_cents
    rental.total_price_cents = listing.price_cents * rental.rental_days
    rental.requested_at = Time.current
    rental.save!(validate: false)

    assert_raises(Rental::BookingConflictError) { rental.accept! }
  end

  test "decline! only works on a pending rental" do
    rentals(:pending_request).decline!
    assert rentals(:pending_request).declined?

    assert_raises(Rental::InvalidTransitionError) { rentals(:accepted_booking).decline! }
  end

  test "withdraw! only works for the borrower on a pending rental" do
    rental = rentals(:pending_request)
    assert_raises(Rental::InvalidTransitionError) { rental.withdraw!(by: rental.lender) }

    rental.withdraw!(by: rental.borrower)
    assert rental.cancelled?
  end

  test "cancel! only works for a participant on an accepted, not-yet-started rental" do
    rental = rentals(:accepted_booking)

    assert_raises(Rental::InvalidTransitionError) { rental.cancel!(by: users(:nahuel), reason: "n/a") }

    rental.cancel!(by: rental.borrower, reason: "Change of plans")
    assert rental.cancelled?
    assert_equal "Change of plans", rental.cancellation_reason
  end

  test "cancel! is not allowed once the rental has started" do
    rental = rentals(:accepted_booking)
    rental.update_columns(start_date: Date.yesterday, end_date: Date.tomorrow, status: "active")
    assert_raises(Rental::InvalidTransitionError) { rental.cancel!(by: rental.borrower, reason: "too late") }
  end

  test "activate! and complete! follow the accepted -> active -> completed path" do
    rental = rentals(:accepted_booking)
    rental.activate!
    assert rental.active?

    rental.complete!
    assert rental.completed?
  end
end
