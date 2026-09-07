require "test_helper"

class RentalNotificationsTest < ActiveSupport::TestCase
  test "creating a rental notifies the lender" do
    listing = listings(:tent)
    assert_difference "Notification.count", 1 do
      listing.rentals.create!(borrower: users(:marti), start_date: 25.days.from_now.to_date, end_date: 27.days.from_now.to_date)
    end

    notification = Notification.last
    assert_equal listing.user, notification.recipient
    assert_equal "rental_requested", notification.verb
  end

  test "accept! notifies the borrower" do
    rental = rentals(:pending_request)
    assert_difference "Notification.count", 1 do
      rental.accept!
    end
    assert_equal "rental_accepted", Notification.last.verb
    assert_equal rental.borrower, Notification.last.recipient
  end

  test "decline! notifies the borrower" do
    rental = rentals(:pending_request)
    assert_difference "Notification.count", 1 do
      rental.decline!
    end
    assert_equal "rental_declined", Notification.last.verb
  end

  test "cancel! notifies the other party" do
    rental = rentals(:accepted_booking)
    assert_difference "Notification.count", 1 do
      rental.cancel!(by: rental.borrower, reason: "plans changed")
    end
    assert_equal rental.lender, Notification.last.recipient
  end

  test "activate! and complete! notify both participants" do
    rental = rentals(:accepted_booking)

    assert_difference "Notification.count", 2 do
      rental.activate!
    end

    assert_difference "Notification.count", 2 do
      rental.complete!
    end
  end
end
