require "test_helper"

module Account
  class LendsControllerTest < ActionDispatch::IntegrationTest
    test "requires authentication" do
      get account_lends_url
      assert_redirected_to new_session_url
    end

    test "shows only rentals where the current user is the lender, filtered by status" do
      sign_in_as users(:marti) # lender on pending_request

      get account_lends_url(status: "pending")
      assert_response :success
      assert_select ".rental-row", count: 1
    end

    test "does not show rentals where the current user is only the borrower" do
      sign_in_as users(:marti) # borrower on accepted_booking, not lender
      get account_lends_url(status: "accepted")
      assert_response :success
      assert_select ".rental-row", count: 0
    end
  end
end
