require "test_helper"

module Rentals
  class AcceptancesControllerTest < ActionDispatch::IntegrationTest
    test "the lender can accept a pending request" do
      rental = rentals(:pending_request)
      sign_in_as rental.lender

      post rental_acceptance_url(rental)

      assert_redirected_to rental_path(rental)
      assert rental.reload.accepted?
    end

    test "the borrower cannot accept their own request" do
      rental = rentals(:pending_request)
      sign_in_as rental.borrower

      post rental_acceptance_url(rental)

      assert_redirected_to root_url
      assert rental.reload.pending?
    end
  end
end
