require "test_helper"

class AvailabilityBlockTest < ActiveSupport::TestCase
  test "an owner can block dates with no existing rental" do
    listing = listings(:tent)
    start_date = 50.days.from_now.to_date

    block = AvailabilityBlock.create_for!(listing: listing, start_date: start_date, end_date: start_date + 2)
    assert block.persisted?
  end

  test "cannot block dates that overlap an accepted rental" do
    rental = rentals(:accepted_booking)

    assert_raises(AvailabilityBlock::BookingConflictError) do
      AvailabilityBlock.create_for!(listing: rental.listing, start_date: rental.start_date, end_date: rental.end_date)
    end
  end

  test "the database rejects two overlapping blocks on the same listing" do
    listing = listings(:tent)
    start_date = 60.days.from_now.to_date
    AvailabilityBlock.create_for!(listing: listing, start_date: start_date, end_date: start_date + 3)

    assert_raises(AvailabilityBlock::BookingConflictError) do
      AvailabilityBlock.create_for!(listing: listing, start_date: start_date + 1, end_date: start_date + 2)
    end
  end
end
