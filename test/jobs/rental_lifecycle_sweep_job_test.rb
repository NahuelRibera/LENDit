require "test_helper"

class RentalLifecycleSweepJobTest < ActiveSupport::TestCase
  test "activates accepted rentals whose start date has arrived" do
    rental = rentals(:accepted_booking)
    rental.update_columns(start_date: Date.yesterday, end_date: Date.tomorrow)

    RentalLifecycleSweepJob.perform_now

    assert rental.reload.active?
  end

  test "completes active rentals whose end date has passed" do
    rental = rentals(:accepted_booking)
    rental.update_columns(status: "active", start_date: 5.days.ago.to_date, end_date: 1.day.ago.to_date)

    RentalLifecycleSweepJob.perform_now

    assert rental.reload.completed?
  end

  test "leaves rentals that are not yet due alone" do
    rental = rentals(:accepted_booking)
    RentalLifecycleSweepJob.perform_now
    assert rental.reload.accepted?
  end
end
