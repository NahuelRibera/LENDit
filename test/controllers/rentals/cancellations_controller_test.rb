require "test_helper"

module Rentals
  class CancellationsControllerTest < ActionDispatch::IntegrationTest
    test "the borrower can withdraw their own pending request" do
      rental = rentals(:pending_request)
      sign_in_as rental.borrower

      post rental_cancellation_url(rental)

      assert_redirected_to rental_path(rental)
      assert rental.reload.cancelled?
    end

    test "either participant can cancel an accepted, not-yet-started booking" do
      rental = rentals(:accepted_booking)
      sign_in_as rental.lender

      post rental_cancellation_url(rental)

      assert_redirected_to rental_path(rental)
      assert rental.reload.cancelled?
    end

    test "a non-participant cannot cancel" do
      sign_in_as users(:nahuel)
      post rental_cancellation_url(rentals(:pending_request))
      assert_redirected_to root_url
    end
  end
end
